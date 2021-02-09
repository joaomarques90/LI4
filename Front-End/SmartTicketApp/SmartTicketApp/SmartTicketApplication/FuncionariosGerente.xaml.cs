using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;
using Xamarin.Forms.Xaml;
using System.Collections;
namespace SmartTicketApplication
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class FuncionariosGerente : ContentPage
    {
        TcpClient client;
        public FuncionariosGerente(TcpClient client)
        {
            this.client = client;
            InitializeComponent();
           
          //  funcionariosListView.BindingContext = GetFuncionarios(); 
            funcionariosListView.ItemsSource = GetFuncionarios();
        }

        private IEnumerable<Funcionario> GetFuncionarios()
        {
            List<Funcionario> funcionarios = new List<Funcionario>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getFuncionarios/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                string[] resultado = recebido.Split('/');
                if (resultado[0].Equals("RespostaNumFuncionarios")) { result = int.Parse(resultado[1]); }

                while (result > 0)
                {
                    string stringFunc = sr.ReadLine();
                    Console.WriteLine("received: " + stringFunc + "\n");
                    funcionarios.Add(Funcionario.stringToFuncionario(stringFunc));
                    result--;
                    Console.WriteLine("Result: " + result + "\n");
                }
                return funcionarios;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        private async void funcionariosListView_ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            if (e.SelectedItem == null)
            {
                return;
            }
            var selectedFuncionario = e.SelectedItem as Funcionario;
            int id = selectedFuncionario.get_id();
            List<Ticket> tickets = new List<Ticket>();
            string result = await DisplayActionSheet("Escolha uma opção", "Ok", "Cancelar", "Por dia", "Por semana", "Por mês", "Por ano");
            if(result.Equals("Por dia"))
            {
                tickets = GetTicketsFuncDia(id);
            }
            if (result.Equals("Por semana"))
            {
                tickets = GetTicketsFuncSemana(id);
            }
            if (result.Equals("Por mês"))
            {
                tickets = GetTicketsFuncMes(id);
            }
            if (result.Equals("Por ano"))
            {
                tickets = GetTicketsFuncAno(id);
            }
            await Navigation.PushAsync(new TicketsFuncionario(tickets));
            funcionariosListView.SelectedItem = null;

        }

        private List<Ticket> GetTicketsFuncDia(int id)
        {
            List<Ticket> tickets = new List<Ticket>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getTicketsFuncDia/"+ id + "/";
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

        private List<Ticket> GetTicketsFuncSemana(int id)
        {
            List<Ticket> tickets = new List<Ticket>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getTicketsFuncSemana/" + id + "/";
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


        private List<Ticket> GetTicketsFuncMes(int id)
        {
            List<Ticket> tickets = new List<Ticket>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getTicketsFuncMes/" + id + "/";
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


        private List<Ticket> GetTicketsFuncAno(int id)
        {
            List<Ticket> tickets = new List<Ticket>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getTicketsFuncAno/" + id + "/";
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
    }
}
