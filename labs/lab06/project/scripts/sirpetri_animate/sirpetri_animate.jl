using DrWatson
@quickactivate "project"
include(srcdir("SIRPetri.jl"))
using .SIRPetri
using DataFrames, CSV, Plots

β = 0.3
γ = 0.1
tmax = 100.0

net, u0, states = build_sir_network(β, γ)

df_det = simulate_deterministic(net, u0, (0.0, tmax), saveat = 0.5, rates = [β, γ])
state_cols = [col for col in propertynames(df_det) if col != :time]

ymax = maximum(Matrix(df_det[:, state_cols]))

anim = @animate for i in 1:nrow(df_det)
    t = df_det.time[1:i]
    y = Matrix(df_det[1:i, state_cols])
    plot(
        t,
        y,
        label = reshape(["S (Susceptible)", "I (Infected)", "R (Recovered)"], 1, :),
        xlabel = "Time",
        ylabel = "Population",
        title = "SIR dynamics at t = $(round(df_det.time[i], digits=2))",
        xlims = (0, tmax),
        ylims = (0, ymax + 10),
        linewidth = 2,
        legend = :topright
    )
end

gif(anim, plotsdir("sir_animation.gif"), fps = 10)
println("Анимация сохранена в plots/sir_animation.gif")
