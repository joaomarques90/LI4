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
    public partial class TicketsFuncionario : ContentPage
    {
        public TicketsFuncionario(List<Ticket> tickets)
        {
            InitializeComponent();
            ticketsListView.ItemsSource = tickets;
        }

        private async void ticketsListView_ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            if (e.SelectedItem == null)
            {
                return;
            }


            var ticket = e.SelectedItem as Ticket;
            await Navigation.PushAsync(new TicketDetailPage(ticket));
            ticketsListView.SelectedItem = null;
        }
    }
}
