using DrWatson
@quickactivate "project"
include(srcdir("mmc_model.jl"))

using DataFrames, CSV, Plots

# Делаем прогон - получаем на выходе массив данных
log = setup_and_run(seed=123, num_customers=10, num_servers=2, mu=1.0 / 2, lam=0.9,)

df = DataFrame(log)

CSV.write(datadir("mmc_run.csv"), df)

times = Float64[]
clients_in_system = Int[]

current_clients = 0

for row in eachrow(df)
    if row.event == "arrived"
        global current_clients += 1
    elseif row.event == "exitedService"
        global current_clients -= 1
    end

    push!(times, row.time)
    push!(clients_in_system, current_clients)
end

system_df = DataFrame(
    time=times,
    clients_in_system=clients_in_system,
)

CSV.write(datadir("clients_in_system.csv"), system_df)

p = plot(
    system_df.time,
    system_df.clients_in_system,
    seriestype=:steppost,
    xlabel="Время моделирования",
    ylabel="Число клиентов в системе",
    title="Число клиентов в системе M/M/c",
    legend=false,
)

savefig(p, plotsdir("mmc_events.png"))

println("Симуляция завершена. Результат в data/mmc_run.csv")
