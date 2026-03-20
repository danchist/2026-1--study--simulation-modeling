using DrWatson
@quickactivate "project"
using Agents
using DataFrames
using Plots

# ## Использование основного скрипта в папке /src
include(srcdir("daisyworld.jl"))

# # Создание модели daisyworld
using CairoMakie
model = daisyworld()

daisycolor(a::Daisy) = a.breed


# # Построение графиков
plotkwargs = (
    agent_color=daisycolor, agent_size = 20, agent_marker = '✿',
    heatarray = :temperature,
    heatkwargs = (colorrange = (-20, 60),),
)

# ## Шаг 1
plt1, _ = abmplot(model; plotkwargs...)

# ## Шаг 5
step!(model, 5)
plt2, _ = abmplot(model; heatarray = model.temperature, plotkwargs...)

# ## Шаг 40
step!(model, 40)
plt3, _ = abmplot(model; heatarray = model.temperature, plotkwargs...)

# ## Сохранение графиков
save(plotsdir("daisy_step001.png"), plt1)
save(plotsdir("daisy_step005.png"), plt2)
save(plotsdir("daisy_step040.png"), plt3)