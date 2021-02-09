using System;
using System.Collections.Generic;
using System.Text;

namespace SmartTicketApplication
{
    class EstatisticasTempoRealView
    {
			public String CongestaoAtual;
			public String TempoAtendimento;
			public String TempoEspera;
		public EstatisticasTempoRealView(EstatisticasTempoRealData estatistica)
		{

			CongestaoAtual = "Congestão Atual - " + estatistica.CongestaoAtual;
			TempoAtendimento = "Ticket com acesso ao sistema - " + estatistica.TempoAtendimento;
			TempoEspera = "Tempo espera ótimo - " + estatistica.TempoEspera + " minutos";
			
		}
	}
}
