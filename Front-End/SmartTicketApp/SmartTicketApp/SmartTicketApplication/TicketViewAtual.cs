using System;
using System.Collections.Generic;
using System.Text;

namespace SmartTicketApplication
{
    public class TicketViewAtual
    {
		public string Servico { get; set; }
		public string Data { get; set; }
		public string Nr_Acesso { get; set; }
		public string Nr_Atual { get; set; }
		public string Estado { get; set; }
	    public string Observacoes{ get; set; }






        public TicketViewAtual(Ticket ticket)
        {
			Servico = "Serviço - " + ticket.nomeServico;
			Data = "Data - " + ticket.data.ToString();
			Nr_Acesso = "Número do ticket - " + ticket.nr_acesso;
			Nr_Atual = "Número do ticket com acesso ao serviço - " + ticket.nr_atual;
			if (String.IsNullOrEmpty(ticket.observacoes)) Observacoes = "";
			else Observacoes = "Observações: " + ticket.observacoes;

        }
	}
}
