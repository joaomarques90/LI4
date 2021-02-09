using System;
using System.Collections.Generic;
using System.Text;

namespace SmartTicketApplication
{
   public class EstatisticasTempoRealData
    {
        public int CongestaoAtual;
        public double TempoAtendimento;
        public double TempoEspera;

        public EstatisticasTempoRealData(double tempoEspera, int congestaoAtual, double tempoAtendimento)
        {
            this.CongestaoAtual = congestaoAtual;
            this.TempoAtendimento = tempoAtendimento;
            this.TempoEspera = tempoEspera;
        }

        public static EstatisticasTempoRealData stringToEstatisticaData(string estatistica)
        {
            String[] resultado = estatistica.Split('/');
            return new EstatisticasTempoRealData(double.Parse(resultado[0]), int.Parse(resultado[1]), double.Parse(resultado[2]));
        }
    }
}
