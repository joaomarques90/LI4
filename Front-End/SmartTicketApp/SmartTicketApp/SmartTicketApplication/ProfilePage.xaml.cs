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
    public partial class ProfilePage : ContentPage
    {
        TcpClient client;
        Utilizador user; 
        public ProfilePage(TcpClient client)
        {
            this.client = client;
            InitializeComponent();
            NavigationPage.SetHasNavigationBar(this, true);
            var assembly = typeof(MainPage);
            this.user = GetUtilizador();
            numeroUtilizador.Text = this.user.get_nr_telemovel().ToString();
            estrelas.Value = this.user.get_reputacao();


        }

        public Utilizador GetUtilizador()
        {
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "getDataUtilizador/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                string[] resultado = recebido.Split('/');

                return new Utilizador(int.Parse(resultado[0]),float.Parse(resultado[1]));
            }

            catch (Exception ex)
            {
                throw ex;
            }
        }
        private void editButton_Clicked(object sender, EventArgs e)
        {
            Navigation.PushModalAsync(new NavigationPage(new EditAccountPage(this.client,this.user)));
        }

        private void removeButton_Clicked(object sender, EventArgs e)
        {
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "deleteUser/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                string[] resultado = recebido.Split('/');
                if (resultado[0].Equals("deleted")) { MessagingCenter.Send<object>(this, App.EVENT_LAUNCH_LOGIN_PAGE); }
                else DisplayAlert("Erro", "Erro ao apagar user", "Ok");

            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
    }
}