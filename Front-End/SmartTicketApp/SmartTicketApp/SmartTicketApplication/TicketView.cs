using System;
using System.Collections.Generic;
using System.Text;

namespace SmartTicketApplication
{
    public class TicketView
    {	
		public string Servico { get; set; }
		public string Data { get; set; }
		public string Nr_Acesso { get; set; }
		public string Estado { get; set; }
		public string Tempo_Espera { get; set; }
		public string Tempo_atendimento { get; set; }

		public string EstadoData { get; set; }







        public TicketView(Ticket ticket)
        {
			Servico = "Serviço - " + ticket.nomeServico;
			Data = "Data - " + ticket.data.ToString();
			Nr_Acesso = "Numero do ticket - " + ticket.nr_acesso;
			Estado = "Estado do ticket - " + ticket.estado;
			Tempo_Espera = "Tempo de espera - " + ticket.tempo_espera;
			Tempo_atendimento = "Tempo de atendimento - " + ticket.tempo_atendimento;
			
		}
	}
}
