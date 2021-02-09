using System;
using MySql.Data.MySqlClient;

namespace SmartTicket
{
    public class User
    {
        // variaveis de instancia
        private int nr_telemovel;
        private string password;

        // set´s e get´s
        public void set_password(string p) {
            this.password = p;
        }
        
        public void set_nr_telemovel(int n) {
            this.nr_telemovel = n;
        }
        
        public string get_password() {
            return this.password;
        }
        
        public int get_nr_telemovel() {
            return this.nr_telemovel;
        }
        
        
    }

}