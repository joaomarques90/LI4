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
    public partial class HorarioAtendimento : ContentPage
    {
        int flag = 0;
        TcpClient client;
        public HorarioAtendimento(TcpClient client)
        {
            this.client = client;
            InitializeComponent();
            Tuple<TimeSpan, TimeSpan> time = getHorarioAtendimento();
            _timePickerAbertura.Time = time.Item1;
            _timePickerFecho.Time = time.Item2;
            switchServico.IsToggled = getEstado();
            estrelas.Value = getRating();
            flag = 1;
        }

        private void switch_Toggled(object sender, ToggledEventArgs e)
        {
            setEstado(e.Value); 
        }

        private void _timePickerAbertura_PropertyChanged(object sender, System.ComponentModel.PropertyChangedEventArgs e)
        {
            if(e.PropertyName == "Time" && (flag == 1))
            {
                setHorarioAtendimento(_timePickerAbertura.Time.Hours, _timePickerAbertura.Time.Minutes, _timePickerFecho.Time.Hours, _timePickerFecho.Time.Minutes);
            }
        }

        public void setHorarioAtendimento(int horaAbertura,int minAbertura, int horaFecho, int minFecho)
        {
            try { 
            NetworkStream stream = client.GetStream();
            StreamReader sr = new StreamReader(stream);
            StreamWriter sw = new StreamWriter(stream);
            int result = 0;
            string request = "setHorarioAtendimento/"+horaAbertura+"/"+minAbertura+"/"+horaFecho+"/"+minFecho+"/";
            sw.WriteLine(request);
            sw.Flush();
            string recebido = sr.ReadLine();
            Console.WriteLine("recebido " + recebido);
            string[] resultado = recebido.Split('/');
                if (resultado[0].Equals("horarioSet")) { return; }
                else DisplayAlert("Erro", "Erro ao mudar horário", "Ok");
            
        }
            catch (Exception ex)
            {
                throw ex;
            }
       }

        public float getRating()
        {
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getRating/" ;
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                string[] resultado = recebido.Split('/');
                if (resultado[0].Equals("rating")) { return  float.Parse(resultado[1]); }

                else { DisplayAlert("Erro", "Erro ao receber horário", "Ok"); return 0; }

            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        public void setRating(float rating)
        {
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                string request = "setRating/" + rating + "/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                string[] resultado = recebido.Split('/');
                if (resultado[0].Equals("ratingSet")) { return; }
                else DisplayAlert("Erro", "Erro ao mudar rating", "Ok");

            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        public Boolean getEstado()
        {
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getEstado/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                string[] resultado = recebido.Split('/');
                if (resultado[0].Equals("estadoGet")) { return Boolean.Parse(resultado[1]); }
                else { DisplayAlert("Erro", "Erro no get estado", "ok"); return false; }

            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        public void setEstado(Boolean input)
        {
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                string request = null;
                if (input == true) request = "setEstado/1";
                else request = "setEstado/0";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                string[] resultado = recebido.Split('/');
                if (resultado[0].Equals("estadoSet")) { return ; }
                else { DisplayAlert("Erro", "Erro no set estado", "ok");}

            }
            catch (Exception ex)
            {
                throw ex;
            }
        }


        public Tuple<TimeSpan, TimeSpan> getHorarioAtendimento()
        {
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getHorarioAtendimento/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                string[] resultado = recebido.Split('/');
                if (resultado[0].Equals("horarioGet")) { return new Tuple<TimeSpan, TimeSpan>(TimeSpan.Parse(resultado[1]), TimeSpan.Parse(resultado[2])); }

                else { DisplayAlert("Erro", "Erro ao receber horário", "Ok"); return new Tuple<TimeSpan, TimeSpan>(new TimeSpan(), new TimeSpan()); }

            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        private void _timePickerFecho_PropertyChanged(object sender, System.ComponentModel.PropertyChangedEventArgs e)
        {
            if (e.PropertyName == "Time" && (flag==1))
            {
                setHorarioAtendimento(_timePickerAbertura.Time.Hours, _timePickerAbertura.Time.Minutes, _timePickerFecho.Time.Hours, _timePickerFecho.Time.Minutes);
            }
        }

        private void estrelas_ValueChanged(object sender, Syncfusion.SfRating.XForms.ValueEventArgs e)
        {
            float newRep =Convert.ToSingle(e.Value);
            setRating(newRep);
        }
    }
}