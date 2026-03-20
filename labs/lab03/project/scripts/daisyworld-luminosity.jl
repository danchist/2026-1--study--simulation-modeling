using DrWatson
@quickactivate "project"
using Agents
using DataFrames
using Plots


# # Использование daisyworld.jl в папке /src
include(srcdir("daisyworld.jl"))

using CairoMakie


# # Параметры модели
black(a) = a.breed == :black
white(a) = a.breed == :white
adata = [(black, count), (white, count)]

model = daisyworld(solar_luminosity = 1.0, scenario = :ramp)

# Использование StatsBase для фиксирования температуры в каждой клетке
temperature(model) = StatsBase.mean(model.temperature)
mdata = [temperature, :solar_luminosity]

# # Запуск модели
agent_df, model_df = run!(model, 1000; adata = adata, mdata = mdata)

# # Построение графиков

# ## Изменение числа маргариток
figure = CairoMakie.Figure(size = (600, 600));
ax1 = figure[1, 1] = Axis(figure, ylabel = "daisy count")
blackl = lines!(ax1, agent_df[!, :time], agent_df[!, :count_black], color = :red)
whitel = lines!(ax1, agent_df[!, :time], agent_df[!, :count_white], color = :blue)
figure[1, 2] = Legend(figure, [blackl, whitel], ["black", "white"])

# ## Изменение температуры и альбедо
ax2 = figure[2, 1] = Axis(figure, ylabel = "temperature")
ax3 = figure[3, 1] = Axis(figure, xlabel = "tick", ylabel = "luminosity")
lines!(ax2, model_df[!, :time], model_df[!, :temperature], color = :red)
lines!(ax3, model_df[!, :time], model_df[!, :solar_luminosity], color = :red)
for ax in (ax1, ax2); ax.xticklabelsvisible = false; end
figure

# # Сохранение графика
save(plotsdir("daisy_luminosity.png"), figure)