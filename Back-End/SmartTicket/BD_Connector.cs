using System;
using MySql.Data.MySqlClient;

namespace SmartTicket {
    public class BD_Connection {
        private MySqlConnection connector;
        public MySqlConnection get_connector() {
            return this.connector;
        }

        public BD_Connection(string user, string pass) {
            string conn = "Server=iqueue.mysql.database.azure.com; Port=3306; Database= iqueue; Uid=" + user + "@iqueue" + "; Pwd=" + pass + "; SslMode=Preferred;";
            Console.WriteLine(conn);
            this.connector = new MySqlConnection(conn);
        }
            
        public BD_Connection()
        {
           
            string conn =  "Server=iqueue.mysql.database.azure.com; Port=3306; Database= iqueue; Uid=guestDB@iqueue; SslMode=Preferred;";
            this.connector = new MySqlConnection(conn);

        }

        public void open_connection() {
            try {
                Console.WriteLine($"Connecting....");
                this.connector.Open();
                Console.WriteLine($"MySQL version : {this.connector.ServerVersion}");
            }
            catch (Exception e) {
                throw e;
            }
        }

        public void close_connection() {
            try {
                this.connector.Close();
            }
            catch (Exception e) {
                throw e;
            }
        }
    }
}
