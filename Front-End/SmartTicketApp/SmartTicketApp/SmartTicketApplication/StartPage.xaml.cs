using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace SmartTicketApplication
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class StartPage : ContentPage
    {
        private TcpClient client;
        public StartPage()
        {
            this.client = new TcpClient();
            client.Connect("10.0.2.2",8888);
            InitializeComponent();
            var assembly = typeof(MainPage);
            iconImage.Source = ImageSource.FromResource("SmartTicketApplication.Assets.Images.IQ.png", assembly);
        }

        private void LoginButton_Clicked(object sender, EventArgs e)
        {
            try
            {
                Navigation.PushModalAsync(new NavigationPage(new LoginPage(this.client)));
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        private void RegisterButton_Clicked(object sender, EventArgs e)
        {
            try
            {
                Navigation.PushModalAsync(new NavigationPage(new RegisterPage(this.client)));
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }
    }
}