using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace SmartTicketApplication{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class RegisterFuncionario : ContentPage{
        private TcpClient client;
        public RegisterFuncionario(TcpClient client){
            this.client = client;
            InitializeComponent();
        }

        private void RegisterButton_OnClicked(object sender, EventArgs e){
            try
            {
                var nome = this.nome.Text;
                var pass = password.Text;
                var nr_tlm = nrTelemovel.Text;
                var confPass = ConfirmarPassword.Text;
                if (String.IsNullOrEmpty(nome) || String.IsNullOrEmpty(pass) || nr_tlm.Length > 9 ||
                    String.IsNullOrEmpty(nr_tlm) || String.IsNullOrEmpty(confPass) || !confPass.Equals(pass)){
                    DisplayAlert("Erro", "Dados inválidos", "Ok");
                    return;
                }
                else{
                    NetworkStream stream = client.GetStream();
                    StreamReader sr = new StreamReader(stream);
                    StreamWriter sw = new StreamWriter(stream);
                    string request = "addFuncionário/" + int.Parse(nr_tlm) + "/" + pass + "/" + nome + "/";
                    sw.WriteLine(request);
                    sw.Flush();
                    string reply = sr.ReadLine();
                    string[] resultado = reply.Split('/');
                    if (resultado[0].Equals("FuncionarioAdded")) Navigation.PopAsync();
                    else DisplayAlert("Erro no Registro", "Ocorreu um erro no registo, tente novamente", "Ok");
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
    }
}