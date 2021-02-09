using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Runtime.InteropServices.WindowsRuntime;
using System.Threading;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Xamarin.Essentials;
namespace SmartTicket{
    public class Automatico
    {
        private int client_id;
        private Boolean cancela;
        
        private Dictionary<Tuple<int,int>, CancellationTokenSource> tasks; // <servico1,servico2>
        
        private string keyMap = "AIzaSyDRhpmlpEUZgLnCYpDROsqOcJtBfiAc4vo";
        private string apiMap = "https://maps.googleapis.com/maps/api/";
        
        private int    marginOr                 = 5;    // minutes
        private int    maxDifTravelAttendance   = 10;   // minutes
        private double safeTimePercentage       = 0.25;
        private int    activeSleepSequence      = 60;   // seconds
        private int    minRadiusServiceSequence = 1000; // meters
        private Facade facade;

        private Dictionary<int,int> log_tickets; // <servicoid,ticketNr> 

        public Automatico(int client_id,Facade facade) {
            client_id = client_id;
            tasks = new Dictionary<Tuple<int,int>, CancellationTokenSource>();
            log_tickets = new Dictionary<int,int>();
            cancela = false;
            this.facade = facade;
        }

        public Automatico(int client_id, int _margin,Facade facade) {
            client_id = client_id;
            marginOr = _margin;
            cancela = false;
            tasks = new Dictionary<Tuple<int,int>, CancellationTokenSource>(); 
            log_tickets = new Dictionary<int,int>();
            this.facade = facade;
        }

        public void cancelarTicket(int servico1, int servico2) // (-1,id) ; (id,-1) ; (id,id)
        {
            Tuple<int,int> t1 = new Tuple<int,int>(servico1, servico1);
            Tuple<int,int> t2 = new Tuple<int,int>(servico2, servico1);
            Tuple<int,int> t3 = new Tuple<int,int>(servico1, servico2);
            Tuple<int,int> t4 = new Tuple<int,int>(servico2, servico2);

            if(tasks.ContainsKey(t1)) {
                if(log_tickets.ContainsKey(servico1)) {facade.cancelar_ticket_automatico(log_tickets[servico1]);
                    log_tickets.Remove(servico1);
                }
                tasks[t1].Cancel();
            }
            if(tasks.ContainsKey(t2))  {
                if(log_tickets.ContainsKey(servico2)) {facade.cancelar_ticket_automatico(log_tickets[servico2]);
                    log_tickets.Remove(servico2);
                }
                if(log_tickets.ContainsKey(servico1)) {facade.cancelar_ticket_automatico(log_tickets[servico1]);
                    log_tickets.Remove(servico1);
                }
                tasks[t2].Cancel();
            }
            if(tasks.ContainsKey(t3))  {
                if(log_tickets.ContainsKey(servico1)) {facade.cancelar_ticket_automatico(log_tickets[servico1]);
                    log_tickets.Remove(servico1);
                }
                if(log_tickets.ContainsKey(servico2)) {facade.cancelar_ticket_automatico(log_tickets[servico2]);
                    log_tickets.Remove(servico2);
                }
                tasks[t3].Cancel();
            }
            if(tasks.ContainsKey(t4))  {
                if(log_tickets.ContainsKey(servico2)) {facade.cancelar_ticket_automatico(log_tickets[servico2]);
                    log_tickets.Remove(servico2);
                }
                tasks[t4].Cancel();
            }
            
        }

        /*
         * Calcula o timeToAttendnce
         * ticketsFrent -> nr de tickets que estao ate ser atendido
         * estDia,estSem,estMes,estAno -> estatisticas do atendiemnto medio nesses periodos
         */
        private double tempoTicket(int idservico) 
        {
          //  bool noStats = false; // existe
          int ticketsFrent = facade.get_estatistica_tempo_real(idservico).get_congestao();
            double estDia = facade.get_estatistica_diaria(idservico).get_tempo_atendimento();
            double estSem = facade.get_estatistica_semanal(idservico).get_tempo_atendimento();
            double estMes = facade.get_estatistica_mensal(idservico).get_tempo_atendimento();
            
            
            double res = 0.0;
            if(estDia == res) // no stats available in the day
                res = ticketsFrent * ((estSem * 0.6) + (estMes * 0.4) );
            else res =  ticketsFrent * ((estDia * 0.5) + (estSem * 0.3) + (estMes * 0.2));
            
            return res;
            
        }
        
        
        /*
        * Given an address return GeoCords      
        */
        public Tuple<String, String> getGeoCordsFromaddress(String address) 
        {
        
            string url = apiMap + "geocode/json?address=" + address + "&key=" + keyMap;

            WebRequest request = WebRequest.Create(url);

            WebResponse response = request.GetResponse();

            Stream data = response.GetResponseStream();
                        
            if(data == null)
                throw new Exception("Api google maps: empty response!");
            
            StreamReader reader = new StreamReader(data);
            
            // json-formatted string from maps api
            string responseFromServer = reader.ReadToEnd();
            Console.WriteLine(responseFromServer);
            response.Close();
            
            return getGeoCordsByAdress(responseFromServer);
        }

        /*
        * Given GeoCords return an address         
        */
        private String getaddressByGeoCords(Tuple<string, string> cords)
        {

            string url = apiMap + "geocode/json?latlng=" + cords.Item1 + "," + cords.Item2 + "&key=" + keyMap;
   
            WebRequest request = WebRequest.Create(url);

            WebResponse response = request.GetResponse();

            Stream data = response.GetResponseStream();
            
            if(data == null)
                throw new Exception("Api google maps: empty response!");
            
            StreamReader reader = new StreamReader(data);
            
            // json-formatted string from maps api
            string responseFromServer = reader.ReadToEnd();

            response.Close();
            return responseFromServer;
        }

        /*
        * travel mode:
        *     "driving" (default) indicates distance calculation using the road network.
        *     "walking" requests distance calculation for walking via pedestrian paths & sidewalks (where available).
        *     "bicycling" requests distance calculation for bicycling via bicycle paths & preferred streets (where available).
        *     "transit" requests distance calculation via public transit routes (where available).  
        */
        private string getInfoFromRoute(Tuple<string, string> ori, Tuple<string, string> dest, string travelMode)
        {
           string url = apiMap + "distancematrix/json?&origins=" + 
                        ori.Item1 + "," + ori.Item2 + "&destinations=" + dest.Item1 + "," + dest.Item2 +"&mode=" + travelMode+ "&key=" + keyMap;

            WebRequest request = WebRequest.Create(url);

            WebResponse response = request.GetResponse();

            Stream data = response.GetResponseStream();
            
            if(data == null)
                throw new Exception("Api google maps: empty response!");
            
            StreamReader reader = new StreamReader(data);
            
            // json-formatted string from maps api
            string responseFromServer = reader.ReadToEnd();

            response.Close();
           
            return responseFromServer;
        }

        public async Task<Tuple<double, double>> getGeoLocation()
        {
           try
           {

               var request = new GeolocationRequest(GeolocationAccuracy.Medium);
              
               var location = await Geolocation.GetLocationAsync(request);
               
               Console.WriteLine($"Latitude: {location.Latitude}, Longitude: {location.Longitude}, Altitude: {location.Altitude}");
               
               return new Tuple<double, double>(location.Latitude,location.Longitude);
           }
           catch (FeatureNotSupportedException fnsEx)
           {
               Console.WriteLine("Handle not supported on device exception");
               throw fnsEx;
           }
           catch (FeatureNotEnabledException fneEx)
           {
               Console.WriteLine("Handle not enabled on device exception");
               throw fneEx;
           }
           catch (PermissionException pEx)
           {
               Console.WriteLine("Handle permission exception");
               throw pEx;
           }
           catch (Exception ex)
           {
               Console.WriteLine("Unable to get location");
               throw ex;
           }
           
  
        }
        // get Geocord by adress
        public Tuple<String,String> getGeoCordsByAdress(string responseFromServer)
        {
            try
            {
                dynamic res = JObject.Parse(responseFromServer);
                // latitude
                string lat = res.results[0].geometry.location.lat;
                // longitude
                string lon = res.results[0].geometry.location.lng;
                
                return new Tuple<string, string>(lat,lon);
            }
            catch (Exception e)
            {
                throw  new Exception("Não foi possivel obter as geocordenadas do address fornecido!");
            }
        }

        // get time route
        private double getTempoPercurso(string responseFromServer)
        {
            try
            {
                dynamic res = JObject.Parse(responseFromServer);
                // time value is in seconds
                string time = res.rows[0].elements[0].duration.value;
                return double.Parse(time);
            }
            catch (Exception e)
            {
                throw  new Exception("Não foi possivel calcular a rota!");
            }
        }
        
        // get the distance from route 
        private double getDistanciaPercurso(string responseFromServer)
        {
            try
            {
                dynamic res = JObject.Parse(responseFromServer);
                
                // time value is in meters
                string distance = res.rows[0].elements[0].distance.value;
 
                return double.Parse(distance);
            }
            catch (Exception e)
            {
                throw  new Exception("Não foi possivel calcular a rota!");
            }
        }

        
            /*
              * Tira um ticket consoante localizaçao
              */
             public void tiraTicket(int servicoid, Tuple<string,string> ori, Tuple<string,string> dest, bool comGeo, string travelMode, float repMinima)
             {
                 if(log_tickets.ContainsKey(servicoid)) {
                     throw new Exception("Já contem em modo automatico servico " + servicoid);
                 };
     
                 int ticketNr; // nr do ticket
                 // json-formatted string from maps api
                 string responseFromServer = getInfoFromRoute(ori, dest,travelMode);
                 
                 double timeTravel = getTempoPercurso(responseFromServer); // convert time, at this point, is in seconds
                 Console.WriteLine("Time to travel "+TimeSpan.FromSeconds(timeTravel));
                 
                 double timeToAttendance = tempoTicket(servicoid); // response in seconds
                 
                 // timeToAttendance get time from function => tempoTicket(boolean s);
                 if (timeTravel <=  timeToAttendance)
                 {
                     string info = "Localizacao origem = " + ori + " ; Com Geolocalizacao = " + comGeo + " ; Modo de deslocacao = " + travelMode;
                     // take ticket
                     Ticket ticket = facade.ticket_automatico(servicoid, info);
                     Console.WriteLine("TIREI O TICKET "+ DateTime.Now.ToString());
                     ticketNr = ticket.get_id();
                     log_tickets.Add(servicoid,ticketNr);
     
                 }
                 else // timeToAttendance > timeTravel
                 {   
     
                     Boolean temClassificaçao = (repMinima<=facade.get_dados_utilizador().get_reputacao()); 
                     if(!temClassificaçao) throw new Exception("Sem reputação necessaria para retirar Ticket");
     
                     var tokenSource = new CancellationTokenSource();
                     CancellationToken ct = tokenSource.Token;
                     Tuple<int,int> tupServi = new Tuple<int, int>(servicoid, servicoid);
                     
                     tasks.Add(tupServi, tokenSource); 
     
                     Task t = Task.Run(() =>
                     {
                         
                         int timeToWait; // seconds
                         int margin = marginOr * 60; // X min in seconds
                         string info = "";
                         do
                         {
                             // at this point we have the value to wait
                             // until we can take the ticket and add the extra value of error in sec
                             // timeTravel is always bigger that timeToAttendace when is inside this loop
                             if ((timeTravel - timeToAttendance) < maxDifTravelAttendance * 60) // maxDifTravelAttendance
                             {
                                 timeToWait = (int) Math.Round(((timeTravel - timeToAttendance) + margin)); // .25 will drop the value very little 
                             }
                             else
                             {  
                                 timeToWait = (int) Math.Round(((timeTravel - timeToAttendance) + margin ) * safeTimePercentage);
                                 // *.25 in case if a lot of people come to the store, the system don´t be "surprised", and this way we get a better
                                 // time to take the ticket
                             }
     
                             Thread.Sleep(timeToWait * 1000);     
                             
                             // if we get the metod cacelatTicket(servicoID), this will be activated, and call the thread, and the sleep mode
                             if (ct.IsCancellationRequested)
                             {
                                 // take of the ticket from the tasks
                                 tasks.Remove(tupServi);
                                 ct.ThrowIfCancellationRequested();
                             }
                             
                             timeTravel -= timeToWait;
 
                             timeToAttendance = tempoTicket(servicoid);
     
                         } while (timeTravel > timeToAttendance);
                         
                         info = "Localizacao origem = " + ori + " ; Com Geolocalizacao = " + comGeo + " ; Modo de deslocacao = " + travelMode;
                         Ticket ticket = facade.ticket_automatico(servicoid, info);
                         Console.WriteLine("TIREI O TICKET "+ DateTime.Now.ToString());
                         ticketNr = ticket.get_id();
                         log_tickets.Add(servicoid,ticketNr);
     
                         // take of the ticket from the tasks
                         tasks.Remove(tupServi);
                     }
                     ,tokenSource.Token); // TASK
                 } // ELSE    
             }
        

        /*
        *  Tira um ticket consoante Tempo de chegada
        */
        public void tiraTicketTemp(DateTime date, int servicoid, float repMinima, TimeSpan hrfecho)
        {
            Boolean temClssificaçao = (repMinima<=facade.get_dados_utilizador().get_reputacao()); 
            if(!temClssificaçao)
                throw new Exception("Sem reputação necessaria para retirar Ticket");

            
            /*DateTime.Compare(T1,T2)>0
             * Greater or equal that zero, t1 is later  or equal that t2. 
             */
            if(TimeSpan.Compare(hrfecho,date.TimeOfDay) < 0)
                throw new Exception("A hora de chegada invalida!");
            
            // If data.now is superior, then it means that the given date is already gone 
            if(DateTime.Compare(DateTime.Now,date) > 0)
                throw new Exception("A DATA INDICADA É INVALIDA");

            TimeSpan timetravelAux = date - DateTime.Now;
            double timeTravel = timetravelAux.TotalSeconds;

            double timeToAttendance = tempoTicket(servicoid);
            
            string info = "Localizacao origem = NULL ; Com Geolocalizacao = False ; Modo de deslocacao = Unknown ";

            if (timeTravel <=  timeToAttendance)
            {
                // take ticket
                Ticket ticket = facade.ticket_automatico(servicoid, info);
                int ticketNr = ticket.get_id();
                log_tickets.Add(servicoid,ticketNr);

            }
            else
            {
                int timeToWait; // seconds
                int margin = marginOr * 60; // X min in seconds

                var tokenSource = new CancellationTokenSource();
                CancellationToken ct = tokenSource.Token;
                Tuple<int,int> tupServi = new Tuple<int, int>(servicoid, servicoid);
                tasks.Add(tupServi, tokenSource);
                Task t = Task.Run(() =>
                {
                    do
                    {
                        // at this point we have the value to wait
                        // until we can take the ticket and add the extra value of error in sec
                        // timeTravel is always bigger that timeToAttendace when is inside this loop
                        if ((timeTravel - timeToAttendance) < maxDifTravelAttendance * 60)
                        {

                            timeToWait =
                                (int) Math.Round(((timeTravel - timeToAttendance) + margin
                                    )); // .25 will drop the value very little 
                        }
                        else
                        {  
                            timeToWait = (int) Math.Round(((timeTravel - timeToAttendance)+margin ) * safeTimePercentage); 
                            // *.25 in case if a loot of people come to the store, the system don´t be "surprised", and this way we get a better
                            // time to take the ticket

                        }
                        
                        // were we sleep the time to wait until, in ms
                        Thread.Sleep(timeToWait * 1000);
                        
                        // At this point thee timeTravel will decrease the time that sleep
                        timeTravel -= timeToWait;
                        // if we get the method cacelatTicket(servicoID), this will be activated, and cancel the thread
                        if (ct.IsCancellationRequested)
                        {
                            // take of the ticket from the tasks
                            tasks.Remove(tupServi);
                            
                            //throw cancellation of thread 
                            ct.ThrowIfCancellationRequested();
                        }
                        
                        timeToAttendance =  tempoTicket(servicoid);
                        
                    } while (timeTravel > timeToAttendance);
                   
                    //in the end of the cycle the system take the ticket
                    Ticket ticket = facade.ticket_automatico(servicoid, info);
                    int ticketNr = ticket.get_id();
                    log_tickets.Add(servicoid,ticketNr);
                   
                    // takes of the ticket from the tasks
                    tasks.Remove(tupServi);
                },tokenSource.Token);
            }
            
        }


        
       
        /*
        *  Tira 2 Tickets
        */
        /* 
        public void tiraSeqTicket(Tuple<string,string> ori, Tuple<string,string> place1, Tuple<string,string> place2, 
                                    int servico1, int servico2,string travelMode)
        {
            string response1  = getInfoFromRoute(ori, place1,travelMode); // get info from ori to place1 
            double routeTime1 = getTempoPercurso(response1); // get time route from ori to place1

            string response2  = getInfoFromRoute(ori, place2,travelMode); // get info from ori to place2
            double routeTime2    = getTempoPercurso(response2); // get time route from ori to place2

            double timeToAtendance1 = tempoTicket(servico1); // time to atendance  in serviço1
            double timeToAtendance2 = tempoTicket(servico2); // time to atendance  in serviço2

            string responsePla1Pla2 = getInfoFromRoute(ori, place2,travelMode); // get info from place1 to place2
            double timeRoutePla1Pla2    = getTempoPercurso(responsePla1Pla2); // get time route from place1 to place2

            /* Ticket can't exceed the time of workplace (done)
             * Ticket have to be extra time for the other (done)
             * maior(routTime1,timeToAtendace) < maior(routTIme2,timeToAttendace2)
             * if the first is smaller, then this is the place that the costumer will go (done)
             *   1       -  10           = 9 => can only be attended in 10 min
             *   10      -  1            = 9 => can only be attended in 10 min
             *  this and the second place is still open
             */
            /*
            double timeOfAttendaceMedium1 = 1; // API -> BackEnd -> get_ESTATISTICA_TEMPO_REAL_tempo_atendimento(idServico1) ***************************************
            double timeOfAttendaceMedium2 = 1; // API -> BackEnd -> get_ESTATISTICA_TEMPO_REAL_tempo_atendimento(idServico2) ***************************************
            
            int margin = marginOr * 60; // X in min 
            
            double test1 = Math.Max(routeTime1,timeToAtendance1) + timeRoutePla1Pla2 + timeOfAttendaceMedium1+ (margin*3); // margin*3 because client will go too two places, entry, out, entry
            double test2 = Math.Max(routeTime2,timeToAtendance2) + timeRoutePla1Pla2 + timeOfAttendaceMedium2+ (margin*3); // margin*3 because client will go too two places, entry, out, entry
            
            DateTime hrfecho1 = new DateTime(2020,06,27,18,00,00); // API -> BackEnd -> get_Servico_hr_fecho(idServirco1) ****************************************************
            DateTime hrfecho2 = new DateTime(2020,06,27,18,00,00); // API -> BackEnd -> get_Servico_hr_fecho(idServirco2) ****************************************************

            DateTime hrFinal1 = DateTime.Now.AddSeconds(test1); // time that user will arrive to the place2
            DateTime hrFinal2 = DateTime.Now.AddSeconds(test2); // time that user will arrive to the place1

            Boolean foraRaio = true; // if the radius is inferior to 1km this will become false
            
            var tokenSource = new CancellationTokenSource();
            CancellationToken ct = tokenSource.Token;
            Tuple<int,int> tupServi = new Tuple<int, int>(servico1,servico2);
            tasks.Add(tupServi, tokenSource);
            
            if (Math.Max(routeTime1,timeToAtendance1) < Math.Max(routeTime2,timeToAtendance2))
            {
                /*DateTime.Compare(T1,T2)>0
                 * Greater or equal that zero, t1 is later  or equal that t2. 
                 */
        /*
                if (DateTime.Compare(hrfecho2, hrFinal2) >= 0)
                {
                    // at this time the user can take the ticket for the route, and don t have the trouble of the time exceed the close hour 
                    var t = Task.Run(() => {

                        tiraTicket(servico1, ori, place1, true,travelMode); // takes the ticket 1
                        
                        do
                        {
                            
                            Thread.Sleep( activeSleepSequence * 1000); // will wait 1 min, each loop, until the the the radius is inferior to 1000 meters
                            // var tup = getGeoLocation(); ************************************************************************
                          
                            // if we get the metod cacelatTicket(servicoID), this will be activated, and call the thread, and the sleep mode
                            if (ct.IsCancellationRequested)
                            {
                                
                                // take of the ticket from the tasks
                                tasks.Remove(tupServi);
                                ct.ThrowIfCancellationRequested();
                            }
                            
                            Tuple<string, string> tup = new Tuple<string, string>("41.56115", "-8.391125"); // example

                            // get from geolocation and call matrix to route and get time
                            String s = getInfoFromRoute(tup, place1,travelMode);

                            if (getDistanciaPercurso(s) < minRadiusServiceSequence)
                                foraRaio = false;
                        } while (foraRaio);
                        
                        tiraTicket(servico2, place1, place2, true,travelMode); // takes the ticket 2
                        
                        // take of the ticket from the tasks
                        tasks.Remove(tupServi);
                    },tokenSource.Token);
                }
                else if (DateTime.Compare(hrfecho1, hrFinal1) >= 0)
                {
                    // at this time the user can take the ticket for the route, and don t have the trouble of the time exceed the close hour 
                    var t = Task.Run(() =>{

                        tiraTicket(servico2, ori, place2, true,travelMode);

                        do
                        {
                            
                            Thread.Sleep(activeSleepSequence * 1000); // will wait 1 min, each loop, until the the the radius is inferior to 1000 meters
                            
                            // if we get the method cacelatTicket(servicoID), this will be activated, and call the thread, and the sleep mode
                            if (ct.IsCancellationRequested)
                            {
                           
                                // take of the ticket from the tasks
                                tasks.Remove(tupServi);
                        
                                ct.ThrowIfCancellationRequested();
                            }

                            
                            // var tup = getGeoLocation(); ************************************************************************
                            Tuple<string, string> tup = new Tuple<string, string>("41.56115", "-8.391125"); // example

                            // get from geolocation and call matrix to route and get time
                            String s = getInfoFromRoute(tup, place2,travelMode);

                            if (getDistanciaPercurso(s) < minRadiusServiceSequence)
                                foraRaio = false;
                        } while (foraRaio);

                        tiraTicket(servico1, place2, place1, true,travelMode);
                        // take of the ticket from the tasks
                        tasks.Remove(tupServi);
                    },tokenSource.Token);
                }
                else
                {
                    // TAKE one ? or don t take any, or user decides witch takes 
                }
            }
            else
            {
                /*DateTime.Compare(T1,T2)>0
                    * Greater or equal that zero, t1 is later  or equal that t2. 
                    */
        /*
                if (DateTime.Compare(hrfecho1, hrFinal1) >= 0)
                {
                    // at this time the user can take the ticket for the route, and don t have the trouble of the time exceed the close hour 
                    var t = Task.Run(() =>
                    {

                        tiraTicket(servico2, ori, place2, true,travelMode);

                        do
                        {
                            
                            Thread.Sleep(activeSleepSequence * 1000); // will wait 1 min, each loop, until the the the radius is inferior to 1000 meters
                            
                            // if we get the metod cacelatTicket(servicoID), this will be activated, and call the thread, and the sleep mode
                            if (ct.IsCancellationRequested)
                            {
                           
                                // take of the ticket from the tasks
                                tasks.Remove(tupServi);
                        
                                ct.ThrowIfCancellationRequested();
                            }

                            // var tup = getGeoLocation(); ************************************************************************
                            Tuple<string, string> tup = new Tuple<string, string>("41.56115", "-8.391125"); // example

                            // get from geolocation and call matrix to route and get time
                            String s = getInfoFromRoute(tup, place1,travelMode);

                            if (getDistanciaPercurso(s) < minRadiusServiceSequence)
                                foraRaio = false;
                        } while (foraRaio);

                        tiraTicket(servico1, place2, place2, true,travelMode);
                        
                        // take of the ticket from the tasks
                        tasks.Remove(tupServi);
                    },tokenSource.Token);
                }
                else if (DateTime.Compare(hrfecho2, hrFinal2) >= 0)
                {
                    
                    // at this time the user can take the ticket for the route, and don t have the trouble of the time exceed the close hour 
                    var t = Task.Run(() =>
                    {

                        tiraTicket(servico1, ori, place1, true,travelMode);
                        
                        do
                        {
                            
                            Thread.Sleep(activeSleepSequence * 1000); // will wait 1 min, each loop, until the the the radius is inferior to 1000 meters
                            
                            // if we get the metod cacelatTicket(servicoID), this will be activated, and call the thread, and the sleep mode
                            if (ct.IsCancellationRequested)
                            {
                           
                                // take of the ticket from the tasks
                                tasks.Remove(tupServi);
                        
                                ct.ThrowIfCancellationRequested();
                            }

                            // var tup = getGeoLocation(); ************************************************************************
                            Tuple<string, string> tup = new Tuple<string, string>("41.56115", "-8.391125"); // example

                            // get from geolocation and call matrix to route and get time
                            String s = getInfoFromRoute(tup, place1,travelMode);

                            if (getDistanciaPercurso(s) < minRadiusServiceSequence)
                                foraRaio = false;
                        } while (foraRaio);

                        tiraTicket(servico2, place1, place2, true,travelMode);
                        // take of the ticket from the tasks
                        tasks.Remove(tupServi);
                        
                    },tokenSource.Token);
                }
                else
                {
                    // TAKE one ? or don t take any, or user decides which takes 
                }
            }
        }
        */
    }
}
