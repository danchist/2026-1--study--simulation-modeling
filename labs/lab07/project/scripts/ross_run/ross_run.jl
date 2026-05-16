using DrWatson
@quickactivate ".."

include(srcdir("ross_model.jl"))

using DataFrames
using CSV
using Plots
using Statistics

function build_repairmen_state(log_df, num_repairmen, stop_time)
    sort!(log_df, :time)

    times = [0.0]
    busy_repairmen = [0]
    current_busy = 0

    for row in eachrow(log_df)
        if row.event == "repair_start"
            current_busy += 1
            push!(times, row.time)
            push!(busy_repairmen, current_busy)
        elseif row.event == "repair_end"
            current_busy -= 1
            push!(times, row.time)
            push!(busy_repairmen, current_busy)
        end
    end

    push!(times, stop_time)
    push!(busy_repairmen, current_busy)

    state_df = DataFrame(time=times, busy_repairmen=busy_repairmen)

    busy_area = 0.0

    for i in 1:(nrow(state_df) - 1)
        dt = state_df.time[i + 1] - state_df.time[i]
        busy_area += state_df.busy_repairmen[i] * dt
    end

    utilization = busy_area / (stop_time * num_repairmen)

    return state_df, utilization
end

function build_repair_queue_state(log_df, stop_time)
    sort!(log_df, :time)

    times = [0.0]
    queue_lengths = [0]
    current_queue = 0

    for row in eachrow(log_df)
        if row.event == "repair_request"
            current_queue += 1
            push!(times, row.time)
            push!(queue_lengths, current_queue)
        elseif row.event == "repair_start"
            current_queue -= 1
            push!(times, row.time)
            push!(queue_lengths, current_queue)
        end
    end

    push!(times, stop_time)
    push!(queue_lengths, current_queue)

    queue_df = DataFrame(time=times, queue_length=queue_lengths)

    queue_area = 0.0

    for i in 1:(nrow(queue_df) - 1)
        dt = queue_df.time[i + 1] - queue_df.time[i]
        queue_area += queue_df.queue_length[i] * dt
    end

    mean_queue_length = queue_area / stop_time

    return queue_df, mean_queue_length
end

function build_good_machines_state(log_df, N, S, stop_time)
    sort!(log_df, :time)

    times = [0.0]
    good_machines = [N + S]
    current_good = N + S

    for row in eachrow(log_df)
        if row.event == "failure"
            current_good -= 1
            push!(times, row.time)
            push!(good_machines, current_good)
        elseif row.event == "repair_end"
            current_good += 1
            push!(times, row.time)
            push!(good_machines, current_good)
        end
    end

    push!(times, stop_time)
    push!(good_machines, current_good)

    return DataFrame(time=times, good_machines=good_machines)
end

RUNS = 5

Ns = [5, 10, 15, 20]
S = 3
NUM_REPAIRMEN = 3

results = DataFrame(
    N=Int[],
    S=Int[],
    num_repairmen=Int[],
    run=Int[],
    crash_time=Float64[],
    utilization=Float64[],
    mean_queue_length=Float64[],
)

all_good_machines = DataFrame(
    N=Int[],
    S=Int[],
    num_repairmen=Int[],
    run=Int[],
    time=Float64[],
    good_machines=Int[],
)

for N in Ns
    for run_id in 1:RUNS
        result = sim_repair(
            N=N,
            S=S,
            num_repairmen=NUM_REPAIRMEN,
            seed=100 + run_id,
            lam=100.0,
            mu=1.0,
        )

        log_df = DataFrame(result.log)

        repairmen_df, utilization = build_repairmen_state(
            log_df,
            NUM_REPAIRMEN,
            result.stop_time,
        )

        queue_df, mean_queue_length = build_repair_queue_state(
            log_df,
            result.stop_time,
        )

        good_df = build_good_machines_state(
            log_df,
            N,
            S,
            result.stop_time,
        )

        good_df.N .= N
        good_df.S .= S
        good_df.num_repairmen .= NUM_REPAIRMEN
        good_df.run .= run_id

        append!(
            all_good_machines,
            good_df[:, [:N, :S, :num_repairmen, :run, :time, :good_machines]],
        )

        push!(results, (
            N=N,
            S=S,
            num_repairmen=NUM_REPAIRMEN,
            run=run_id,
            crash_time=result.stop_time,
            utilization=utilization,
            mean_queue_length=mean_queue_length,
        ))

        if N == 10 && run_id == 1
            CSV.write(datadir("ross", "log_example.csv"), log_df)
            CSV.write(datadir("ross", "repairmen_state_example.csv"), repairmen_df)
            CSV.write(datadir("ross", "repair_queue_example.csv"), queue_df)
        end
    end
end

CSV.write(datadir("ross_results.csv"), results)
CSV.write(datadir("all_good_machines.csv"), all_good_machines)

summary = combine(
    groupby(results, [:N, :num_repairmen]),
    :crash_time => mean => :mean_crash_time,
    :crash_time => std => :std_crash_time,
    :utilization => mean => :mean_utilization,
    :mean_queue_length => mean => :mean_queue_length,
)

CSV.write(datadir("ross", "ross_summary.csv"), summary)

# График

one_run = filter(
    row -> row.N == 10 && row.run == 1,
    all_good_machines,
)

sort!(one_run, :time)

CSV.write(datadir("ross", "good_machines_one_run.csv"), one_run)

p1 = plot(
    one_run.time,
    one_run.good_machines,
    seriestype=:steppost,
    xlabel="Время моделирования",
    ylabel="Число исправных машин",
    title="Фрагмент динамики исправных машин",
    legend=false,
    xlims=(0, 80),
    ylims=(10, 14),
)

savefig(p1, plotsdir("machines_one_run_small_1.png"))

p2 = plot(
    one_run.time,
    one_run.good_machines,
    seriestype=:steppost,
    xlabel="Время моделирования",
    ylabel="Число исправных машин",
    title="График динамики исправных машин",
    legend=false,
    xlims=(0, 1000),
    ylims=(10, 14),
)

savefig(p2, plotsdir("machines_one_run_large.png"))

p3 = plot(
    one_run.time,
    one_run.good_machines,
    seriestype=:steppost,
    xlabel="Время моделирования",
    ylabel="Число исправных машин",
    title="Фрагмент динамики исправных машин",
    legend=false,
    xlims=(200, 300),
    ylims=(10, 14),
)

savefig(p3, plotsdir("machines_one_run_small_2.png"))


println(summary)
