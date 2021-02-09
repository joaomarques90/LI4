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
	public partial class TicketsPage : ContentPage
	{
        private TcpClient client;
		

		public TicketsPage(TcpClient client)
		{
			InitializeComponent();
            this.client = client;
			TicketlistView.ItemsSource = GetTicketsUser();
		}

     
        private async void TicketlistView_ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
			if (e.SelectedItem == null)
			{
				return;
			}


			var ticket = e.SelectedItem as Ticket;
			await Navigation.PushAsync(new TicketDetailPageAtual(ticket,this.client));
			TicketlistView.SelectedItem = null;
		}

        private List<Ticket> GetTicketsUser()
        {
            List<Ticket> tickets = new List<Ticket>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getTicketsUserAtuais/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                string[] resultado = recebido.Split('/');
                if (resultado[0].Equals("RespostaNumTickets")) { result = int.Parse(resultado[1]); }

                while (result > 0)
                {
                    string stringTicket = sr.ReadLine();
                    Console.WriteLine("received: " + stringTicket + "\n");
                    tickets.Add(Ticket.stringToTicket(stringTicket));
                    result--;
                    Console.WriteLine("Result: " + result + "\n");
                }
                return tickets;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        private void TicketlistView_OnRefreshing(object sender, EventArgs e){
	        TicketlistView.ItemsSource = GetTicketsUser();
	        TicketlistView.EndRefresh();
        }
	}
}