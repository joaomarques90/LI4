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
    public partial class RegisterPage : ContentPage
    {
        private TcpClient client;
        private bool smsFlag = false;
        private string resultSMS = null;
        private int tries = 5;
        public RegisterPage(TcpClient client)
        {
            this.client = client;
            InitializeComponent();
        }
       
        private async void  RegisterButton_Clicked(object sender, EventArgs e)
        {
            try{
                var texto = email.Text;
                var pass = password.Text;
                if (String.IsNullOrEmpty(pass) || String.IsNullOrEmpty(texto)) DisplayAlert("Erro", "É necessário escrever uma password e número de telemóvel","Ok");
                else if (!password.Text.Equals(ConfirmarPassword.Text)) DisplayAlert("Erro", "Não confirmou corretamente a password", "Ok");
                else{
                    if (!smsFlag) this.resultSMS = generateSMS(email.Text);

                    if (resultSMS.Equals("OK")){
                        smsFlag = true;
                        string input = await DisplayPromptAsync("Confirmação",
                            "Insira o código de confirmação recebido por sms",
                            "Ok", "Cancelar", "Código", -1, Keyboard.Plain, "");
                        //get codigo sms
                        if (validateSMS(email.Text, input)){
                            registerUser();
                        }
                        else{
                            DisplayAlert("Erro", "Código inserido errado", "Ok");
                        }
                    }
                    else{
                        DisplayAlert("Erro", "Erro " + resultSMS + " ao enviar mensagem, tente novamente", "Ok");
                    }
                }
            }
            catch (Exception ex){
                DisplayAlert("Erro", ex.Message, "Ok");
            }

        }
        
        private string generateSMS(string tlm){
            try
            {
                if (String.IsNullOrEmpty(tlm) || tlm.Length != 9 ){
                    DisplayAlert("Erro", "É necessário escrever um número de telemóvel válido","Ok");
                    return "Número inválido";
                }
                else {
                    NetworkStream stream = client.GetStream();
                    StreamReader sr = new StreamReader(stream);
                    StreamWriter sw = new StreamWriter(stream);
                    string request = "generateSMS/" +tlm+ "/";
                    sw.WriteLine(request);
                    sw.Flush();
                    string reply = sr.ReadLine();
                    string[] resultado = reply.Split('/');
                    if (resultado[0].Equals("generateSMSResult")) return resultado[1];
                    else{
                        DisplayAlert("Erro", "Erro ao conectar ao servidor", "Ok");
                        return "Erro ao conectar ao servidor";
                    }
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        
        private bool validateSMS(string tlm,string input){
            try
            {       NetworkStream stream = client.GetStream();
                    StreamReader sr = new StreamReader(stream);
                    StreamWriter sw = new StreamWriter(stream);
                    string request = "validateSMS/" + tlm + "/" + input + "/";
                    sw.WriteLine(request);
                    sw.Flush();
                    string reply = sr.ReadLine();
                    string[] resultado = reply.Split('/');
                    if (resultado[0].Equals("validateSMSResult") ) return bool.Parse(resultado[1]);
                    DisplayAlert("Erro na validação", "Ocorreu um erro na validação, tente novamente", "Ok"); 
                    return false;
                
              
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        private void registerUser(){
            try{
                var texto = email.Text;
                var pass = password.Text;
                 NetworkStream stream = client.GetStream();
                 StreamReader sr = new StreamReader(stream);
                 StreamWriter sw = new StreamWriter(stream);
                 string request = "Register/" + int.Parse(texto) + "/" + pass + "/";
                 sw.WriteLine(request);
                 sw.Flush();
                 string reply = sr.ReadLine();
                 string[] resultado = reply.Split('/');
                 if (resultado[0].Equals("RegisterOk")) Navigation.PushModalAsync(new NavigationPage(new LoginPage(this.client)));
                 else DisplayAlert("Erro no Registro", "Ocorreu um erro no registo, tente novamente", "Ok");
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
    }
}