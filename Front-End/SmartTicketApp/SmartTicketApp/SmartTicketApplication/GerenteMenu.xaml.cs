﻿using System;
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
    public partial class GerenteMenu : ContentPage
    {
        private TcpClient client;
        private int idTicket = 0;
        public GerenteMenu(TcpClient client ,String ticket=null)
        {
            this.client = client;
            InitializeComponent();
        }

        private async void atender_Clicked(object sender, EventArgs e)
        {
            await Navigation.PushModalAsync(new AtenderTicketGerente(this,this.client));
        }

      
        protected override bool OnBackButtonPressed()
        {
            
            return false;
        }

        public async void ticketSelected(Ticket ticket)
        {
            if (ticket == null) ;
            else
            {
                ticketNumber.Text = ticket.nr_acesso.ToString();
                this.idTicket = ticket.id;
                AtendeTicket(this.idTicket);
            }
        }

        private void atendido_Clicked(object sender, EventArgs e){
            if (idTicket > 0){
                TicketAtendido(this.idTicket);
            idTicket = 0;
            ticketNumber.Text = "Selecione novo ticket";
            return;
            }
           DisplayAlert("Erro", "Selecione um Ticket primeiro", "Ok");
         }
        
        public void TicketAtendido(int id)
        {
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "usarTicket/"+this.idTicket+"/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                string[] resultado = recebido.Split('/');
                if (resultado[0].Equals("TicketUsado")) return;
                DisplayAlert("Erro", "Erro ao dar ticket como atendido", "Ok");
            }

            catch (Exception ex)
            {
                throw ex;
            }
        }

        public void AtendeTicket(int id)
        {
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "atenderTicket/" + this.idTicket + "/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                string[] resultado = recebido.Split('/');
                if (resultado[0].Equals("TicketAtendido")) return;
                DisplayAlert("Erro", "Erro ao atender ticket", "Ok");

            }

            catch (Exception ex)
            {
                throw ex;
            }
        }
    }
}