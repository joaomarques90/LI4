using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;
using Xamarin.Forms.Xaml;
using System.Net.Sockets;
using System.IO;
using System.Net.Http.Headers;

namespace SmartTicketApplication
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class MenuServices : ContentPage
    {
        private Servico servico;
        private TcpClient client;
        private Boolean favorito;
        private double latitude;
        private double longitude;
        public MenuServices(Servico servicos,TcpClient client,double lat, double longitude)
        {
            if (servicos == null)  ;
            this.client = client;
            this.servico = servicos;
            this.latitude = lat;
            this.longitude = longitude;
            InitializeComponent();
            favorito = isFavorito();
           if(!favorito)
           listView.ItemsSource = new List<MenuItems> { new MenuItems { OptionName = "Estatisticas em tempo real" }, new MenuItems { OptionName = "Histórico" }, new MenuItems { OptionName = "Retirar Ticket" }, new MenuItems { OptionName = "Informações" }, new MenuItems { OptionName = "Adicionar aos Favoritos" } };
            else listView.ItemsSource = new List<MenuItems> { new MenuItems { OptionName = "Estatisticas em tempo real" }, new MenuItems { OptionName = "Histórico" }, new MenuItems { OptionName = "Retirar Ticket" }, new MenuItems { OptionName = "Informações" }, new MenuItems { OptionName = "Remover dos Favoritos" } };
        }

        public EstatisticasTempoRealData GetEstatisticasTempoReal()
        {
            List<string> categorias = new List<string>();
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getEstatisticasTempoReal/" + this.servico.get_id() + "/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                string[] resultado = recebido.Split('/');

                return EstatisticasTempoRealData.stringToEstatisticaData(recebido);
            }

            catch (Exception ex)
            {
                throw ex;
            }
        }

        public int addFavorito()
        {
   
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                string request = "addFavorito/" + this.servico.get_id() + "/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                if (recebido.Equals("Added/")) ;
                else DisplayAlert("Erro", "Erro ao adicionar favorito", "Ok");
                return 1;
         
            }

            catch (Exception ex)
            {
                throw ex;
            }
        }
        public int removeFavorito()
        {

            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                string request = "removeFavorito/" + this.servico.get_id() + "/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                if (recebido.Equals("Removed/")) ;
                else DisplayAlert("Erro", "Erro ao remover favorito", "Ok");
                return 1;

            }

            catch (Exception ex)
            {
                throw ex;
            }
        }

        public Boolean isFavorito()
        {

            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                string request = "containsFavorito/" + this.servico.get_id() + "/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                string[] resultado = recebido.Split('/');
                Console.WriteLine("recebido " + recebido);
                if (resultado[0].Equals("Contains")) return true;
                if (resultado[0].Equals("DoesntContain")) return false;
                return false; 

            }

            catch (Exception ex)
            {
                throw ex;
            }
        }

        async void  Handle_ItemSelected(object sender, Xamarin.Forms.SelectedItemChangedEventArgs e)
        {
            if (e.SelectedItem == null)
            {
                return;
            }

            try
            {
                var item = e.SelectedItem as MenuItems;
                switch (item.OptionName)
                {
                    case "Estatisticas em tempo real":
                        {
                            EstatisticasTempoRealData estatistica = GetEstatisticasTempoReal();
                            await Navigation.PushAsync(new EstatisticasTempoReal(estatistica,this.client)); //mudar para Estatisticas

                        }
                        break;
                    case "Histórico":
                        {

                            await Navigation.PushAsync(new HistoricoDiario(this.servico,this.client)); //mudar para histórico

                        }
                        break;
                    case "Retirar Ticket":
                        {
                            await Navigation.PushAsync(new RetirarTicket(this.servico,this.client,this.latitude,this.longitude)); //mudar para retirarticket

                        }
                        break;
                    case "Informações":
                        {
                            await Navigation.PushAsync(new Contactos(this.servico)); //mudar para contactar
                        }
                        break;
                    case "Adicionar aos Favoritos":
                        {
                            addFavorito();   
                            await Navigation.PopAsync(); 
                        }
                        break;
                    case "Remover dos Favoritos":
                        {
                            
                            removeFavorito();
                            await Navigation.PopAsync();
                        }
                        break;
                }
            }

            catch (Exception ex)
            {
                ex.ToString();
            }
            finally
            {
                listView.SelectedItem = null;
            }
        }
    }
}