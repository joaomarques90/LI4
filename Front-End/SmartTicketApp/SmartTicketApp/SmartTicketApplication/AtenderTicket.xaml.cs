using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;
using Xamarin.Forms.Xaml;
using System.Net.Sockets;
using System.IO;

namespace SmartTicketApplication
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class AtenderTicket : ContentPage
    {
        private TcpClient client;
        private Func_Menu cp;
        public AtenderTicket(Func_Menu c, TcpClient client)
        {
            this.client = client;
            InitializeComponent();
            cp = c;
            listView.ItemsSource = GetTicketsFunc();

        }

        private List<Ticket> GetTicketsFunc()
        {
            List<Ticket> tickets = new List<Ticket>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getTicketsFunc/";
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
        void Handle_ItemSelected(object sender, Xamarin.Forms.SelectedItemChangedEventArgs e)
        {
            var ticket = e.SelectedItem as Ticket;
            //Remover ticket da lista de tickets por atender
           
            popFunc(ticket);
        }
        public void popFunc(Ticket ticket)
        {
            cp.ticketSelected(ticket);
            Navigation.PopModalAsync();
        }
    }
}