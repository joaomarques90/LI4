using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace SmartTicketApplication
{
	public partial class TicketDetailPage : ContentPage
	{
		public TicketDetailPage(Ticket ticket)
		{ 
			if (ticket == null)
				return;
			TicketView view = new TicketView(ticket);
			BindingContext = view;
			InitializeComponent();
		}

	}
}