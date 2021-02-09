using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace SmartTicketApplication
{
	public partial class TicketDetailPageAtual : ContentPage
	{ private Ticket ticket;
        private TcpClient client;
		public TicketDetailPageAtual(Ticket ticket,TcpClient client)
		{
            this.client = client;
			if (ticket == null)
				return;
			this.ticket = ticket;
			TicketViewAtual view = new TicketViewAtual(ticket);
			BindingContext = view;
			InitializeComponent();
		}
		private async void CancelButton_Clicked(object sender, EventArgs e)
		{
			string result = await DisplayActionSheet("Confirmação", "Sim","Não", "Tem a certeza que pretende cancelar o ticket?");
			if (result.Equals("Sim") && String.IsNullOrEmpty(this.ticket.observacoes)){
				CancelarTicket(ticket.id);
				Navigation.PopAsync();
			}
			else if (result.Equals("Sim")){
				CancelarTicketAutomatico(ticket.id);
				Navigation.PopAsync();
			}
            else
            {
				;
            }
		}

		private void CancelarTicket(int id)
        {
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "cancelarTicket/" + id + "/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                string[] resultado = recebido.Split('/');
                if (resultado[0].Equals("TicketCancelado")) return;
                else DisplayAlert("Erro", "Erro ao cancelar ticket", "Ok");
            }

            catch (Exception ex)
            {
                throw ex;
            }
        }
		
		private void CancelarTicketAutomatico(int id)
		{
			try
			{
				NetworkStream stream = client.GetStream();
				StreamReader sr = new StreamReader(stream);
				StreamWriter sw = new StreamWriter(stream);
				int result = 0;
				string request = "cancelarTicketAuto/" + id + "/";
				sw.WriteLine(request);
				sw.Flush();
				string recebido = sr.ReadLine();
				Console.WriteLine("recebido " + recebido);
				string[] resultado = recebido.Split('/');
				if (resultado[0].Equals("TicketCancelado")) return;
				else DisplayAlert("Erro", "Erro ao cancelar ticket", "Ok");
			}

			catch (Exception ex)
			{
				throw ex;
			}
		}
	}
}