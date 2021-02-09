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
    public partial class SelecionarCategoria : ContentPage
    {
        private MapPage m;
        public SelecionarCategoria(MapPage mp,List<string> categorias)
        {
            
            
            InitializeComponent();
            m = mp;
            listView.ItemsSource = categorias;
        }

        private void listView_ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {  var categoria = e.SelectedItem as string;
            popFunc(categoria);
        }
        public void popFunc(String categoria)
        {
            m.categorySelected(categoria);
            Navigation.PopModalAsync();
        }
    }
}