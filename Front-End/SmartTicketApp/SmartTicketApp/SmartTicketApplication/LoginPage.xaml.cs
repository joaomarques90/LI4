using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;
using Xamarin.Forms.Xaml;
using System.IO;

namespace SmartTicketApplication
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class LoginPage : ContentPage
    {
        private TcpClient client;
        public LoginPage(TcpClient client)
        {
            this.client = client;
            InitializeComponent();
        }
        private void LoginButton_Clicked(object sender, EventArgs e)
        {
            try {
                
                var texto = email.Text;
                var pass = password.Text;

                if (texto.Length > 9) DisplayAlert("Erro", "nº de telemóvel inválido", "Ok");
                else
                {
                    NetworkStream stream = client.GetStream();
                    StreamReader sr = new StreamReader(stream);
                    StreamWriter sw = new StreamWriter(stream);
                    int result = 0;
                    string request = "Login/" + int.Parse(texto) + "/" + pass + "/";
                    sw.WriteLine(request);
                    sw.Flush();
                    string reply = sr.ReadLine();
                    string[] resultado = reply.Split('/');
                    if (resultado[0].Equals("Resultado do Login")) { result = int.Parse(resultado[1]); }

                    if (result == 0) DisplayAlert("Erro Login", "Conta não existe", "Ok");
                    else if (result == 1) DisplayAlert("Erro Login", "Password Errada", "Ok");
                    else if (result == 2) Navigation.PushModalAsync(new NavigationPage(new MainPage(client)));
                    else DisplayAlert("Erro", "Erro", "Ok");
                }
            }
            catch(Exception ex)
            {
                throw ex;
            }
            
        }

        private void LoginButtonFuncionario_Clicked(object sender, EventArgs e)
        {
            try
            {

                var texto = email.Text;
                var pass = password.Text;
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                int result = 0;
                string request = "LoginFuncGer/" + int.Parse(texto) + "/" + pass + "/";
                sw.WriteLine(request);
                sw.Flush();
                string reply = sr.ReadLine();
                string[] resultado = reply.Split('/');
                if (resultado[0].Equals("Resultado do Login")) { result = int.Parse(resultado[1]); }

                if (result == 0) DisplayAlert("Erro Login", "Conta não existe", "Ok");
                else if (result == 1) DisplayAlert("Erro Login", "Password errada", "Ok");
                else if (result == 2) Navigation.PushModalAsync(new NavigationPage(new MainPageGerente(client)));
                else if (result == 3) Navigation.PushModalAsync(new NavigationPage(new Func_Menu(client)));
                else DisplayAlert("Erro", "Erro", "Ok");
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
    }
}