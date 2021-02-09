
using Plugin.Geolocator;
using Plugin.Geolocator.Abstractions;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace SmartTicketApplication
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class RetirarTicket : ContentPage
    { private Servico servicoAtual;
        private TcpClient client;
        private double latitude;
        private double longitude;
        public RetirarTicket(Servico servicos,TcpClient client,double latitude, double longitude)
        {
            this.client = client;
            this.latitude = latitude;
            this.longitude = longitude;
            servicoAtual = servicos;
            InitializeComponent();
            data.Date = DateTime.Now;
            
        }
        
        private void Button_HoraClicked(object sender, EventArgs e)
        {
            TimeSpan time = hora.Time;
            DateTime result = new DateTime(data.Date.Year, data.Date.Month, data.Date.Day, time.Hours, time.Minutes, time.Seconds);
            TakeTicketHora(result, this.servicoAtual.get_id());
        }

        private async void Button_LocalizacaoClicked(object sender, EventArgs e){
            Boolean comGPS = false;
            string gps = await DisplayActionSheet("Com ou sem GPS?", null, null, "Com GPS", "Sem GPS");
            if (gps.Equals("Com GPS")){
                comGPS = true;
                if (this.latitude == 0 || this.longitude == 0) DisplayAlert("Erro", "A aplicação não tem acesso à sua localização", "Ok");
                else{
                    
                }
                string result = await DisplayActionSheet("Método de transporte", "Cancelar", null, "Carro", "A pé", "Transporte público");
                string metodo = null;
                if (result.Equals("Carro")) metodo = "driving";
                else if (result.Equals("A pé")) metodo = "walking";
                else if (result.Equals("Transporte público")) metodo = "transit";
                else return;
                TakeTicketLocalGPS(this.servicoAtual.get_id(),this.latitude.ToString("G",CultureInfo.InvariantCulture),this.longitude.ToString("G",CultureInfo.InvariantCulture),this.servicoAtual.get_latitude().ToString("G",CultureInfo.InvariantCulture),this.servicoAtual.get_longitude().ToString("G",CultureInfo.InvariantCulture),comGPS,metodo,this.servicoAtual.get_reputacaoMinima());
            }    
            if (gps.Equals("Sem GPS")){
                string endereço = await DisplayPromptAsync("Localização","Qual o endereço","Ok","Cancelar","Endereço",-1,Keyboard.Plain,"");
                string result = await DisplayActionSheet("Método de transporte", "Cancelar", null, "Carro", "A pé", "Transporte público");
                string metodo = null;
                if (result.Equals("Carro")) metodo = "driving";
                else if (result.Equals("A pé")) metodo = "walking";
                else if (result.Equals("Transporte público")) metodo = "transit";
                else return;
                TakeTicketLocal(this.servicoAtual.get_id(),endereço,this.servicoAtual.get_latitude().ToString("G",CultureInfo.InvariantCulture),this.servicoAtual.get_longitude().ToString("G",CultureInfo.InvariantCulture),comGPS,metodo,this.servicoAtual.get_reputacaoMinima());
            }
            
           

        }
        private void Button_SimplesClicked(object sender, EventArgs e)
        {
            int result = TakeTicketSimples(this.servicoAtual.get_id());
            if (result != 0)
                DisplayAlert("Ticket retirado", "Foi retirado com sucesso o ticket nº " + result, "Ok");
            else DisplayAlert("Insucesso", "O serviço pretendido encontra-se indisponivel ou já possui um ticket ativo ou a sua reputação é insuficiente","Ok");
        }

        public int TakeTicketSimples(int id)
        {
            try
            {
                
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                string request = "getTicketSimples/" + id + "/";
                int result = 0;
                sw.WriteLine(request);
                sw.Flush();
                string reply = sr.ReadLine();
                string[] resultado = reply.Split('/');
                if (resultado[0].Equals("TicketNumero")) { result = int.Parse(resultado[1]);  }
                else DisplayAlert("Erro ao obter ticket", "Ocorreu um erro na obtenção do ticket, tente novamente", "Ok");
                return result;
            }
            catch (Exception ex)
            {
                throw ex;
            }
        } 
        
        public void TakeTicketHora(DateTime date,int id)
        {
            try
            {
                
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                string request = "getTicketHora/" + date.ToString("s") + "/" + id + "/" + this.servicoAtual.get_reputacaoMinima()+"/"+this.servicoAtual.get_horaFecho()+"/";
                sw.WriteLine(request);
                sw.Flush();
                string reply = sr.ReadLine();
                string[] resultado = reply.Split('/');
                if (resultado[0].Equals("TicketASerRetirado")) { return;  }

                if (resultado[0].Equals("Exception")){
                    DisplayAlert("Erro", resultado[1], "Ok");
                    return;
                }
               DisplayAlert("Erro ao obter ticket", "Ocorreu um erro na obtenção do ticket, tente novamente", "Ok");
               
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        
        public void TakeTicketLocalGPS(int id,string latitudeOrigem,string longitudeOrigem,string latitudeDestino,string longitudeDestino,Boolean comGPS,string travelMode,float repMinima)
                {
                    try
                    {
                        
                        NetworkStream stream = client.GetStream();
                        StreamReader sr = new StreamReader(stream);
                        StreamWriter sw = new StreamWriter(stream);
                        string request = "getTicketLocalGPS/" + id+ "/" + latitudeOrigem + "/" + longitudeOrigem+"/"+ latitudeDestino+"/"+ longitudeDestino + "/"+ comGPS + "/" + travelMode + "/"+ repMinima+ "/";
                        
                        sw.WriteLine(request);
                        sw.Flush();
                        string reply = sr.ReadLine();
                        string[] resultado = reply.Split('/');
                        if (resultado[0].Equals("TicketASerRetirado")){
                            ;
                        }

                        else if (resultado[0].Equals("Exception")){
                            DisplayAlert("Erro", resultado[1], "Ok");

                        }
                        else
                            DisplayAlert("Erro ao obter ticket",
                                "Ocorreu um erro na obtenção do ticket, tente novamente", "Ok");

                    }
                    catch (Exception ex)
                    {
                        throw ex;
                    }
                }
        
        public void TakeTicketLocal(int id,string address,string latitudeDestino,string longitudeDestino,Boolean comGPS,string travelMode,float repMinima)
        {
            try
            {
                        
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                string request = "getTicketLocal/" + id+ "/" + address + "/" + latitudeDestino+"/"+ longitudeDestino + "/"+ comGPS + "/" + travelMode + "/"+ repMinima+ "/";
                        
                sw.WriteLine(request);
                sw.Flush();
                string reply = sr.ReadLine();
                string[] resultado = reply.Split('/');
                if (resultado[0].Equals("TicketASerRetirado")) { return;  }
        
                if (resultado[0].Equals("Exception")){
                    DisplayAlert("Erro", resultado[1], "Ok");
                    return;
                }
                DisplayAlert("Erro ao obter ticket", "Ocorreu um erro na obtenção do ticket, tente novamente", "Ok");
                       
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
    }
}