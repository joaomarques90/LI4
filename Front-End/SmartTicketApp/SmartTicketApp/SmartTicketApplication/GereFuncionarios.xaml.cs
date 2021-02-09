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
    public partial class GereFuncionarios : ContentPage{
        private TcpClient client;
        private int funcID = 0;
        public GereFuncionarios(TcpClient client){
            this.client = client;
            InitializeComponent();
            funcionariosListView.ItemsSource = GetFuncionarios();
        }

        private void FuncionariosListView_OnItemSelected(object sender, SelectedItemChangedEventArgs e){
            if (e.SelectedItem == null)
            {
                return;
            }
            
            
            var selectedFuncionario = e.SelectedItem as Funcionario;
            funcID = selectedFuncionario.id;
            
        }

        private void FuncionariosListView_OnRefreshing(object sender, EventArgs e){
            funcionariosListView.ItemsSource = GetFuncionarios();
            funcionariosListView.EndRefresh();
        }

        private async void RegistarButton_OnClicked(object sender, EventArgs e){
            await Navigation.PushAsync(new RegisterFuncionario(this.client));
            funcionariosListView.ItemsSource = GetFuncionarios();
        }

        private async void RemoverButton_OnClicked(object sender, EventArgs e){
            
            if (funcID == 0) DisplayAlert("Erro", "Precisa selecionar um funcionário para remover", "Ok");
            else { 
               string result =await DisplayActionSheet("Tem a certeza que deseja remover o funcionário com id " + funcID + " ?", "Sim", "Não");
            if (result.Equals("Sim")){
                RemoverFuncionario(funcID);
                funcionariosListView.SelectedItem = null;
                funcID = 0;
            }
            else{
                funcionariosListView.SelectedItem = null;
                funcID = 0;
            }
                funcionariosListView.ItemsSource = GetFuncionarios();
            }
        }

        private void RemoverFuncionario(int id){
            try
            {
                NetworkStream stream = client.GetStream();
                StreamReader sr = new StreamReader(stream);
                StreamWriter sw = new StreamWriter(stream);
                string request = "removeFuncionário/"+id+"/";
                sw.WriteLine(request);
                sw.Flush();
                string recebido = sr.ReadLine();
                Console.WriteLine("recebido " + recebido);
                string[] resultado = recebido.Split('/');
                if (resultado[0].Equals("FuncionarioRemoved")){
                    ; }
                else{
                    DisplayAlert("Erro", "Erro ao remover funcionário", "Ok");
                }

            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
        private List<Funcionario> GetFuncionarios()
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
    }
}