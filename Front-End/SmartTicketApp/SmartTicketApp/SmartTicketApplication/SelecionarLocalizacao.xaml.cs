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
    public partial class SelecionarLocalizacao : ContentPage
    {
        private MapPage m;
        public SelecionarLocalizacao(MapPage mp, List<string> localizacoes)
        {
            InitializeComponent();
            m = mp;
            listView.ItemsSource = localizacoes;
        }
        private void listView_ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            var localizacao = e.SelectedItem as string;
            popFunc(localizacao);
        }

        public void popFunc(String localizacao)
        {
            m.localizationSelected(localizacao);
            Navigation.PopModalAsync();
        }
    }
}