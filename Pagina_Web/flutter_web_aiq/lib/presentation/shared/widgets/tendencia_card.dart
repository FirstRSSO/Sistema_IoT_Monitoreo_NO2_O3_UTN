import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TendenciaCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final double porcentaje;
  final List<FlSpot> puntos;

  const TendenciaCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.porcentaje,
    required this.puntos,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool esPositivo = porcentaje >= 0;

    return Container(
      width: size.width * 0.48,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text(valor, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Hoy ${esPositivo ? '+' : ''}${porcentaje.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 14,
              color: esPositivo ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 24,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 6,
                      getTitlesWidget: (value, meta) {
                        String text;
                        switch (value.toInt()) {
                          case 0:
                            text = '0h';
                            break;
                          case 6:
                            text = '6h';
                            break;
                          case 12:
                            text = '12h';
                            break;
                          case 18:
                            text = '18h';
                            break;
                          case 24:
                            text = '24h';
                            break;
                          default:
                            return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 4,
                          child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    spots: puntos,
                    barWidth: 3,
                    color: Colors.blueGrey,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: Colors.blueGrey.withOpacity(0.1)),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
