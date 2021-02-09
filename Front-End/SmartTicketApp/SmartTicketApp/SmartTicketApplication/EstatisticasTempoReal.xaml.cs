using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace SmartTicketApplication
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class EstatisticasTempoReal : ContentPage
    {
        TcpClient client;
        public EstatisticasTempoReal(EstatisticasTempoRealData estatistica, TcpClient client)
        { 

           
            
            InitializeComponent();
            EstatisticasTempoRealView view = new EstatisticasTempoRealView(estatistica);
            this.client = client;
            label1.Text = view.CongestaoAtual;
            label2.Text = view.TempoAtendimento;
            label3.Text = view.TempoEspera;
            


        }

        
    }
}