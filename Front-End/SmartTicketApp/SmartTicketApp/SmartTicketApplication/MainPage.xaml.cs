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
    // Learn more about making custom code visible in the Xamarin.Forms previewer
    // by visiting https://aka.ms/xamarinforms-previewer
    [DesignTimeVisible(false)]
    public partial class MainPage : MasterDetailPage
    {
        private List<MenuItems> menu;
        private TcpClient client;
        public MainPage(TcpClient client)
        {
            
            this.client = client;
            InitializeComponent();
           var  menu = new List<MenuItems>();
           var assembly = typeof(MainPage);
           brandImage.Source = ImageSource.FromResource("SmartTicketApplication.Assets.Images.IQ.png", assembly);

            menu.Add(new MenuItems { OptionName = "Os Meus Tickets" });
            menu.Add(new MenuItems { OptionName = "Histórico de Tickets" });
            menu.Add(new MenuItems { OptionName = "Serviços" });
            menu.Add(new MenuItems { OptionName = "Conta" });
            menu.Add(new MenuItems { OptionName = "Logout" });
            menu.Add(new MenuItems { OptionName = "About Us" });
           
            navigationList.ItemsSource = menu;
            Detail = new NavigationPage(new TicketsPage(client));
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
                    case "Os Meus Tickets":
                        {
                            Detail = new NavigationPage(new TicketsPage(client)); //mudar para os meus tickets
                            IsPresented = false;
                        }
                        break;
                    case "Histórico de Tickets":
                        {
                            Detail = new NavigationPage(new HistoricoTickets(client)); //mudar para os meus tickets
                            IsPresented = false;
                        }
                        break;
                    case "Serviços":
                        {
                            Detail = new NavigationPage(new MapPage(this.client)); //mudar para os meus serviços
                            IsPresented = false;
                        }
                        break;
                    case "Conta":
                        {
                            Detail.Navigation.PushAsync(new ProfilePage(this.client)); //mudar para conta
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
                    case "About Us":
                        {
                            Detail = new NavigationPage(new AboutUs());
                            IsPresented = false;
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

    public class MenuItems
    {
        public string OptionName { get; set; }
    }
}
