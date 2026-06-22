/* Find the busiest airport by the number of flights take off */

select top 1 Name, Count(*) as Total_takeoff from dbo.Airports a
join Flights b on a.AirportID = b.Origin
group by Name
order by Total_takeoff desc;

/* Total number of ticekts sold per airline */

with flight_ticket as(
select f.FlightID,f.AirlineID,t.TicketID from Flights f 
join Tickets t on f.FlightID = t.FlightID)

select Name, count(*) as ticket_sold
from flight_ticket ft 
join dbo.Airlines l on ft.AirlineID = l.AirlineID
group by Name
order by ticket_sold desc

/* List All flights operated by 'IndiGo' with airport names (origin and destination) */

select f.AirlineID, f.Destination,f.Origin,
c.Name as DestinationAirport,
b.Name as OriginAirport
from Flights f
inner join Airlines a on f.AirlineID = a.AirlineID
inner join airports b on f.Origin = b.AirportID
inner join Airports c on f.Destination = c.AirportID
where a.Name like '%IndiGo';


/* for each airport, show the top airline by number of flights departing from there */

with FlightRanks AS(
select *,
RANK() over (partition by Origin order by Number_of_flights desc) as Ranking
FROM( select f.Origin,ar.Name as Airport_Name, al.Name as Airline_Name, count(*) as Number_of_flights
from Flights f 
join Airports ar on f.Origin = ar.AirportID
join Airlines al on f.AirlineID = al.AirlineID
group by al.Name, f.Origin, ar.Name)t
)

select * from FlightRanks
where Ranking = 1;

/* For each flight, show time taken in hours and categorize it as short,meidum, and long */

with FlightArrival AS(
select *,
DATEDIFF(hour,DepartureTime,ArrivalTime) as FlightTime
from Flights)

select FlightID,DepartureTime,ArrivalTime,FlightTime,
case when FlightTime between 2 and 5 then 'medium'
     when FlightTime > 5 then 'Long'
     else  'Short'
END as Category 
from FlightArrival

/* show each passenger's first and last flight dates and number of flights */

select p.Name, count(*)as Number_of_flights, 
MAX(f.DepartureTime) as LastFlight,
MIN(f.DepartureTime) as FirstFlight  
from Tickets t
join Passengers p on t.PassengerID = p.PassengerID
join Flights f on t.FlightID = f.FlightID
group by t.PassengerID,p.Name
order by Number_of_flights desc ;

/* Find flights with the highest price ticket sold for each route (origin to destination) */

with routeticekt as(
select f.FlightID, f.Origin,f.Destination,t.TicketID,t.Price,
rank() over (partition by f.Origin, f.Destination order by t.Price desc) as rn
from Tickets t
join Flights f on t.FlightID = f.FlightID)

select A1.Name as Origin, A2.Name as Destination, rt.TicketID,rt.Price
from routeticekt rt
join Airports A1 on rt.Origin = A1.AirportID
join Airports A2 on rt.Destination = A2.AirportID
where rn = 1
order by Price desc


/* Find the highest spending passenger in each frequent Flyer Status group */

with passenger_flyerstatus as(
select p.Name,p.FrequentFlyerStatus,SUM(t.Price) as SUMPrice,
rank() over (partition by FrequentFlyerStatus order by  SUM(t.Price) desc) as rn
from Passengers p
join Tickets t on p.PassengerID = t.PassengerID
group by p.FrequentFlyerStatus,Name)

select * from passenger_flyerstatus
where rn = 1
order by SUMPrice desc;

/* Find the total revenue and number of tickets sold for each airline, and rank airlines basd on total revenue */ 

with total_revenue as(
select a.Name as AirlineName, count(*) as num_tickets,SUM(t.Price) as SUMPrice from Flights f
join Airlines a on f.AirlineID = a.AirlineID
join Tickets t on f.FlightID = t.FlightID
group by a.Name)

select *,
rank() over (order by SUMPrice desc) as Ranking
from total_revenue;

/* For each passenger,identify their most frequently used airline */ 

with passenger_freq_table as(
select p.Name as PassengerName, a.Name as AirlineName,count(*) as freq,
rank() over (partition by (p.Name) order by count(*) desc) as Ranking
from Flights f
join Airlines a on f.AirlineID = a.AirlineID
join Tickets t on f.FlightID = t.FlightID
join Passengers p on t.PassengerID =  p.PassengerID
group by p.Name,a.Name)

select * 
from passenger_freq_table
where Ranking = 1