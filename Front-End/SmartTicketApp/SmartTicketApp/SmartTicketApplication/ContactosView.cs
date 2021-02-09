using System;
using System.Collections.Generic;
using System.Text;

namespace SmartTicketApplication
{
    class ContactosView
    {
        public string email;
        public string telefone;
        public ContactosView(Servico servico){
            email = "Email: " + servico.get_email();
            telefone = "Telefone: " + servico.get_telefone();
        }
    }
    
}
