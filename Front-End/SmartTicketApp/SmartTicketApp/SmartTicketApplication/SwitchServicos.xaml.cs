using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace SmartTicketApplication
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class SwitchServicos : ContentPage
    {
        public SwitchServicos(Servico s)
        {
            InitializeComponent();
 
        }

        private void Switch_Toggled(object sender, ToggledEventArgs e)
        {
            Navigation.PopAsync();
        }
    }
}