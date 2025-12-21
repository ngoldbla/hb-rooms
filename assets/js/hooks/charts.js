// Chart.js hooks for analytics dashboard
// Using Chart.js from CDN loaded in root.html.heex

const RevenueChart = {
  mounted() {
    this.initChart();
  },

  updated() {
    this.updateChart();
  },

  initChart() {
    const data = JSON.parse(this.el.dataset.chartData);
    const ctx = this.el.getContext("2d");

    this.chart = new Chart(ctx, {
      type: "bar",
      data: {
        labels: data.labels,
        datasets: [
          {
            label: "Revenue ($)",
            data: data.data,
            backgroundColor: "rgba(79, 70, 229, 0.8)",
            borderColor: "rgba(79, 70, 229, 1)",
            borderWidth: 1,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          legend: {
            display: false,
          },
          tooltip: {
            callbacks: {
              label: function (context) {
                return "$" + context.parsed.y.toFixed(2);
              },
            },
          },
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              callback: function (value) {
                return "$" + value.toFixed(2);
              },
            },
          },
        },
      },
    });
  },

  updateChart() {
    if (!this.chart) {
      this.initChart();
      return;
    }

    const data = JSON.parse(this.el.dataset.chartData);
    this.chart.data.labels = data.labels;
    this.chart.data.datasets[0].data = data.data;
    this.chart.update();
  },

  destroyed() {
    if (this.chart) {
      this.chart.destroy();
    }
  },
};

const UtilizationChart = {
  mounted() {
    this.initChart();
  },

  updated() {
    this.updateChart();
  },

  initChart() {
    const data = JSON.parse(this.el.dataset.chartData);
    const ctx = this.el.getContext("2d");

    this.chart = new Chart(ctx, {
      type: "bar",
      data: {
        labels: data.labels,
        datasets: [
          {
            label: "Utilization (%)",
            data: data.data,
            backgroundColor: "rgba(16, 185, 129, 0.8)",
            borderColor: "rgba(16, 185, 129, 1)",
            borderWidth: 1,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          legend: {
            display: false,
          },
          tooltip: {
            callbacks: {
              label: function (context) {
                return context.parsed.y.toFixed(2) + "%";
              },
            },
          },
        },
        scales: {
          y: {
            beginAtZero: true,
            max: 100,
            ticks: {
              callback: function (value) {
                return value + "%";
              },
            },
          },
        },
      },
    });
  },

  updateChart() {
    if (!this.chart) {
      this.initChart();
      return;
    }

    const data = JSON.parse(this.el.dataset.chartData);
    this.chart.data.labels = data.labels;
    this.chart.data.datasets[0].data = data.data;
    this.chart.update();
  },

  destroyed() {
    if (this.chart) {
      this.chart.destroy();
    }
  },
};

const TrendChart = {
  mounted() {
    this.initChart();
  },

  updated() {
    this.updateChart();
  },

  initChart() {
    const data = JSON.parse(this.el.dataset.chartData);
    const ctx = this.el.getContext("2d");

    this.chart = new Chart(ctx, {
      type: "line",
      data: {
        labels: data.labels,
        datasets: [
          {
            label: "Revenue ($)",
            data: data.data,
            backgroundColor: "rgba(139, 92, 246, 0.1)",
            borderColor: "rgba(139, 92, 246, 1)",
            borderWidth: 2,
            fill: true,
            tension: 0.4,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          legend: {
            display: false,
          },
          tooltip: {
            callbacks: {
              label: function (context) {
                return "$" + context.parsed.y.toFixed(2);
              },
            },
          },
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              callback: function (value) {
                return "$" + value.toFixed(2);
              },
            },
          },
        },
      },
    });
  },

  updateChart() {
    if (!this.chart) {
      this.initChart();
      return;
    }

    const data = JSON.parse(this.el.dataset.chartData);
    this.chart.data.labels = data.labels;
    this.chart.data.datasets[0].data = data.data;
    this.chart.update();
  },

  destroyed() {
    if (this.chart) {
      this.chart.destroy();
    }
  },
};

export { RevenueChart, UtilizationChart, TrendChart };
