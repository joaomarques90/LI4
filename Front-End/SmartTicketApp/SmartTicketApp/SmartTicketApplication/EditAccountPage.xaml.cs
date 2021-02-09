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
    public partial class EditAccountPage : ContentPage
    {
        private TcpClient client;
        private Utilizador user;
        public EditAccountPage(TcpClient client,Utilizador user)
        {
            this.client = client;
            this.user = user;
            InitializeComponent();
            NavigationPage.SetHasNavigationBar(this, true);

        }
        private void AlterationsButton_Clicked(object sender, EventArgs e)
        {
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                string pass = password.Text;
                string pass1 = ConfirmarPassword.Text;
                if (String.IsNullOrEmpty(pass) || String.IsNullOrEmpty(pass1)){
                    DisplayAlert("Erro", "Tem de preencher os campos password", "Ok");
                    return;
                }
                if (pass.Equals(pass1))
                {
                    string request = "changePassword/" + pass + "/";
                    sw.WriteLine(request);
                    sw.Flush();
                    string recebido = sr.ReadLine();
                    Console.WriteLine("recebido " + recebido);
                    string[] resultado = recebido.Split('/');
                    if (resultado[0].Equals("changed")) { Navigation.PopModalAsync(); }
                    else DisplayAlert("Erro", "Erro ao mudar apagar user", "Ok");
                }
                else DisplayAlert("Erro", "As passwords não coincidem", "Ok");
            }
            catch (Exception ex)
            {
                throw ex;
            }
            
        }
    }
}