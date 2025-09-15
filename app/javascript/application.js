// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import * as bootstrap from "bootstrap"

// Chart.js
import Chart from 'chart.js/auto'

// Inicializar gráficos quando a página carregar
document.addEventListener('DOMContentLoaded', function() {
  initializeCharts()
})

// Inicializar gráficos quando Turbo navegar
document.addEventListener('turbo:load', function() {
  initializeCharts()
})

function initializeCharts() {
  // Inicializar gráfico de comparação SRS-2
  const chartCanvas = document.getElementById('srs2-comparison-chart')
  if (chartCanvas) {
    console.log('Canvas encontrado:', chartCanvas)
    
    try {
      const chartData = JSON.parse(chartCanvas.dataset.chartData)
      console.log('Dados do gráfico:', chartData)
      createSrs2ComparisonChart(chartCanvas, chartData)
    } catch (error) {
      console.error('Erro ao parsear dados do gráfico:', error)
    }
  } else {
    console.log('Canvas não encontrado')
  }
}

function createSrs2ComparisonChart(canvas, chartData) {
  console.log('Criando gráfico com dados:', chartData)
  
  const ctx = canvas.getContext('2d')
  
  // Destruir gráfico existente se houver
  if (window.srs2Chart) {
    window.srs2Chart.destroy()
  }
  
  window.srs2Chart = new Chart(ctx, {
    type: 'line',
    data: {
      labels: chartData.labels,
      datasets: chartData.datasets
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        title: {
          display: true,
          text: 'Comparação SRS-2: Autorrelato vs Heterorrelato',
          font: {
            size: 16,
            weight: 'bold'
          }
        },
        legend: {
          display: true,
          position: 'top',
          labels: {
            usePointStyle: true,
            padding: 20
          }
        },
        tooltip: {
          callbacks: {
            label: function(context) {
              return context.dataset.label + ': T-Score ' + context.parsed.y
            }
          }
        }
      },
      scales: {
        y: {
          beginAtZero: false,
          min: 50,
          max: 90,
          title: {
            display: true,
            text: 'Escore T'
          },
          grid: {
            color: 'rgba(0, 0, 0, 0.1)'
          },
          ticks: {
            stepSize: 5
          }
        },
        x: {
          title: {
            display: true,
            text: 'Domínio avaliado'
          },
          ticks: {
            maxRotation: 45,
            minRotation: 0
          }
        }
      },
      interaction: {
        intersect: false,
        mode: 'index'
      }
    }
  })
  
  console.log('Gráfico criado com sucesso!')
}
