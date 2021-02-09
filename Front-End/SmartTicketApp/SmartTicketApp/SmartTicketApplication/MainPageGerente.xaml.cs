using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;

namespace SmartTicketApplication
{

    [DesignTimeVisible(false)]
    public partial class MainPageGerente : MasterDetailPage
    {
        private List<MenuItems> menu;
        private TcpClient client;
        public MainPageGerente(TcpClient client)
        {
            this.client = client;
            InitializeComponent();
           var  menu = new List<MenuItems>();
           var assembly = typeof(MainPage);
           brandImage.Source = ImageSource.FromResource("SmartTicketApplication.Assets.Images.IQ.png", assembly);

            menu.Add(new MenuItems { OptionName = "Atender Tickets" });
            menu.Add(new MenuItems { OptionName = "Editar Serviço" });
            menu.Add(new MenuItems { OptionName = "Tickets Atendidos" });
            menu.Add(new MenuItems { OptionName = "Gerir Funcionários" });
            menu.Add(new MenuItems { OptionName = "Logout" });
            navigationList.ItemsSource = menu;
            Detail = new NavigationPage(new GerenteMenu(this.client));
        }
        protected override bool OnBackButtonPressed()
        {
          
                base.OnBackButtonPressed();
                return true;
            
        }
        private void Item_Tapped(object sender, ItemTappedEventArgs e)
        {
            try
            {
                var item = e.Item as MenuItems;

                switch (item.OptionName)
                {
                    case "Atender Tickets":
                        {
                            Detail = new NavigationPage(new GerenteMenu(this.client)); 
                            IsPresented = false;
                        }
                        break;
                    case "Editar Serviço":
                        {
                            Detail = new NavigationPage(new HorarioAtendimento(this.client)); //mudar para os serviços do gerente
                            IsPresented = false;
                        }
                        break;
                    case "Tickets Atendidos":
                        {
                            Detail= new NavigationPage(new FuncionariosGerente(this.client)); //mudar para uma lista de funcionarios que selecionando mostrará os tickets atendidos por funcionario
                            IsPresented = false;
                        }
                        break;
                    case "Gerir Funcionários":
                    {
                        Detail = new NavigationPage(new GereFuncionarios(this.client)); //mudar para os serviços do gerente
                        IsPresented = false;
                    }
                        break;
                    
                    case "Logout":
                        { 
                            try
                            {
                                NetworkStream stream = client.GetStream();
                                StreamReader sr = new StreamReader(stream);
                                StreamWriter sw = new StreamWriter(stream);
                                int result = 0;
                                string request = "Logout/";
                                sw.WriteLine(request);
                                sw.Flush();
                                MessagingCenter.Send<object>(this, App.EVENT_LAUNCH_LOGIN_PAGE);
                            }
                            catch (Exception ex)
                            {
                                throw ex;
                            }

                            break;
                        }
                    }
            }
            catch (Exception ex)
            {
                e.ToString();
            }
        }
    }

}
