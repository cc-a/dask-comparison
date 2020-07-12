import matplotlib.pyplot as plt


def speed_up_plot(speed_ups, ax):
    speed_ups.plot.line(ax=ax, x="nproc", add_legend=True)
    coords = speed_ups.coords["nproc"]
    ax.plot(coords, coords, "--")
    ax.set_xlabel("No. of Processors")
    ax.set_ylabel("Speed Up")
    ax.set_title("")


def efficiency_plot(speed_ups, ax):
    coords = speed_ups.coords["nproc"]
    (speed_ups / coords).plot.line(ax=ax, x="nproc", add_legend=True)

    ax.set_xlabel("No. of Processors")
    ax.set_ylabel("Parallel Efficiency")
    ax.set_title("")
    ax.set_ylim(-0.1, 1.1)


def block_size_plot(data, ax):

    data.min(dim="repeat").plot.line(ax=ax, x="block_size", add_legend=True)

    ax.set_xlabel("Block Size")
    ax.set_ylabel("Run time")
    ax.set_title("")


def make_plot(data, title="", plot_types=(speed_up_plot, efficiency_plot)):
    fig, (axes,) = plt.subplots(ncols=len(plot_types), squeeze=False)

    for plot_type, ax in zip(plot_types, axes):
        plot_type(data, ax)

    fig.suptitle(title)
    fig.tight_layout(rect=[0, 0.03, 1, 0.95])
