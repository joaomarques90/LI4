using System;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace SmartTicketApplication
{
    public partial class App : Application
    {
        public static string EVENT_LAUNCH_LOGIN_PAGE = "EVENT_LAUNCH_LOGIN_PAGE";
        public static string EVENT_LAUNCH_MAIN_PAGE = "EVENT_LAUNCH_MAIN_PAGE";
        public static string EVENT_LAUNCH_GER_PAGE = "EVENT_LAUNCH_GER_PAGE";

        public App()
        {
            Syncfusion.Licensing.SyncfusionLicenseProvider.RegisterLicense("Mjc4NDIyQDMxMzgyZTMxMmUzMGszbG5yZDZmWW1nK01KamFiSlZHbm40RXNGYWpMZk9kSTdxT0t2QVZVSkk9");
              InitializeComponent();

            MainPage = new StartPage();

            MessagingCenter.Subscribe<object>(this, EVENT_LAUNCH_LOGIN_PAGE, SetStartAsRootPage);
            
        }
        private void SetStartAsRootPage(object sender)
        {
            MainPage = new StartPage();
        }
        protected override void OnStart()
        {
        }

        protected override void OnSleep()
        {
        }

        protected override void OnResume()
        {
        }
    }
}
