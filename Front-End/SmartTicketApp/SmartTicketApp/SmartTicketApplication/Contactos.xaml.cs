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
    public partial class Contactos : ContentPage
    {
        public Contactos(Servico servico)
        {
            ContactosView contacto = new ContactosView(servico);
            InitializeComponent();
            _timePickerAbertura.Time = servico.get_horaAbertura();
            _timePickerFecho.Time = servico.get_horaFecho();
            estrelas.Value = servico.get_reputacaoMinima();
            Email.Text = contacto.email;
            Telefone.Text = contacto.telefone;
        }
    }
}