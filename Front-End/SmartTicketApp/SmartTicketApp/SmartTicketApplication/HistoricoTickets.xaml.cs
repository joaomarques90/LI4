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
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class HistoricoTickets : ContentPage
    {
        public TcpClient client;
        public HistoricoTickets(TcpClient client)
        {
            this.client = client;
            InitializeComponent();
        }

        private List<Ticket> GetTicketsUserDia()
        {
            List<Ticket> tickets = new List<Ticket>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getTicketsUserDia/";
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

        private List<Ticket> GetTicketsUserSemana()
        {
            List<Ticket> tickets = new List<Ticket>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getTicketsUserSemana/";
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


        private List<Ticket> GetTicketsUserMes()
        {
            List<Ticket> tickets = new List<Ticket>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getTicketsUserMes/";
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


        private List<Ticket> GetTicketsUserAno()
        {
            List<Ticket> tickets = new List<Ticket>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getTicketsUserAno/";
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

        private async void Filtrar_Clicked(object sender, EventArgs e)
        {
            string result = await DisplayActionSheet("Escolha uma opção", "Ok", "Cancelar", "Por dia", "Por semana", "Por Mês", "Por Ano");
            if (result.Equals("Cancelar")) ;
            if (result.Equals("Por dia"))
            {

                HistoricolistView.ItemsSource = GetTicketsUserDia();
            }
            if (result.Equals("Por semana"))
            {
                HistoricolistView.ItemsSource = GetTicketsUserSemana();
            }
            if (result.Equals("Por Mês"))
            {
                HistoricolistView.ItemsSource = GetTicketsUserMes();

            }
            if (result.Equals("Por Ano"))
            {
                HistoricolistView.ItemsSource = GetTicketsUserAno();

            }
        }

        private async void HistoricolistView_ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            if (e.SelectedItem == null)
            {
                return;
            }


            var ticket = e.SelectedItem as Ticket;
            await Navigation.PushAsync(new TicketDetailPage(ticket));
            HistoricolistView.SelectedItem = null;
        }
    }
    
}
