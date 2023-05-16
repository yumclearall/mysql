drop database if exists travel_agency;
create database travel_agency;
use travel_agency;

drop table if exists room;
create table room(
	room_num int primary key,
	room_type  enum('single','double'),
	room_price int not null,
	room_state  enum('empty','busy')  default 'empty'
	);

drop table if exists lodger;
create table lodger(
	lodger_name varchar(32) not null,
	id_l  varchar(18) primary key,

	room_name int unique not null,
	foreign key(room_name) references room(room_num), 

	payment int not null
	);

drop table if exists date;
create table date(
	id varchar(18) primary key,
	checkin_date datetime default now(),
	p_checkout_date datetime default null
	);

drop table if exists checkout;
create table checkout(
	num int auto_increment primary key,
	lodger_name varchar(32) not null,
	id_c varchar(18) not null,
	room_name int,
	lives_days int,
	room_account int,
	back_change int
	);

drop table if exists t_user;
create table t_user(
 id int auto_increment primary key,
 userName varchar(32),
  password varchar(18));
  
insert t_user(userName,password) values('administrator','1234');

drop view if exists v1_room;
create view v1_room as (select r.room_num,r.room_type,l.lodger_name,l.id_l,r.room_price,r.room_state
from room r join lodger l on l.room_name=r.room_num where room_state='busy');  


drop view if exists v2_lodger;
create view v2_lodger as 
(select l.lodger_name,l.id_l,l.room_name,d.checkin_date,d.p_checkout_date,
l.payment from lodger l join date d on d.id=l.id_l);

delimiter //
drop trigger if exists t1_busy;
create trigger t1_busy after insert on lodger
for each row
begin
update room r
set room_state='busy'
where r.room_num=new.room_name;
end	
//
delimiter ;	

delimiter //
drop trigger if exists t2_empty_del;
create trigger t2_empty_del after insert on checkout
for each row
begin
update room r
set room_state='empty'
where r.room_num=new.room_name;
delete from lodger l
where l.room_name=new.room_name;
end	
//
delimiter ;

delimiter //
drop trigger if exists t3_price_error;
create trigger t3_price_error before insert on lodger
for each row
begin
declare price int;
select room_price into price from room where room_num=new.room_name;
if new.payment<price
then insert into lodger values(0);
end if;
end
//
delimiter ;


delimiter //
drop procedure if exists p1_emptyroom;
create procedure p1_emptyroom()
reads sql data
begin
select room_num,room_type,room_price,room_state
from room where room_state='empty' order by room_num;
end
//
delimiter ;

delimiter //
drop procedure if exists p2_busyroom;
create procedure p2_busyroom()
reads sql data
begin
select room_num,room_type,room_price,room_state
from room
where room_state='busy' order by room_num;
end
//
delimiter ;

delimiter //
drop procedure if exists p3_date;
create procedure p3_date(in date date)
reads sql data
begin
select l.lodger_name,l.id_l,l.room_name,d.checkin_date,
d.p_checkout_date,l.payment
from lodger l,date d
where to_days(date)=to_days(d.checkin_date) and l.id_l=d.id;
end 
//
delimiter ;
                                                              
delimiter //
drop procedure if exists p4_h_date;
create procedure p4_h_date(in date date)
reads sql data
begin
select i.lodger_name,i.id_c,i.room_name,d.checkin_date,
d.p_checkout_date,i.lives_days,i.room_account,i.back_change
from checkout i,date d
where  i.id_c=d.id and to_days(date)=to_days(d.checkin_date);
end 
//
delimiter ;

delimiter //
drop procedure if exists p5_lodger;
create procedure p5_lodger(in id1 varchar(18))
reads sql data
begin
select l.lodger_name,l.id_l,room_name,d.checkin_date,d.p_checkout_date,l.payment
from lodger l,date d
where id_l=id1 and d.id=id1;
end 
//
delimiter ;
                     
delimiter //
drop procedure if exists p6_h_lodger;
create procedure p6_h_lodger(in id varchar(18))
reads sql data
begin
select i.lodger_name,i.id_c,i.room_name,d.checkin_date,
d.p_checkout_date,i.lives_days,i.room_account,i.back_change
from date d,checkout i
where i.id_c=d.id and id=i.id_c;
end 
//
delimiter ;

delimiter //
drop procedure if exists p7_checkout;
create procedure p7_checkout(in r_name int,days int)
modifies sql data
begin
declare name varchar(32);
declare id varchar(18);
declare price int;
declare pay_ment int;
select lodger_name into name from lodger where room_name=r_name;
select id_l into id from lodger where room_name=r_name;
select payment into pay_ment from lodger where room_name=r_name;
select room_price into price from room where room_num=r_name;
insert checkout(lodger_name,id_c,room_name,lives_days,room_account,back_change)
 values(name,id,r_name,days,days*price,pay_ment-days*price);
end 
//
delimiter ;

delimiter //
drop procedure if exists p7_ad_checkout;
create procedure p7_ad_checkout(in r_name int,ad_date datetime,days int)
modifies sql data
begin
declare name varchar(32);
declare id_d varchar(18);
declare price int;
declare pay_ment int;
select lodger_name into name from lodger where room_name=r_name;
select id_l into id_d from lodger where room_name=r_name;
select payment into pay_ment from lodger where room_name=r_name;
select room_price into price from room where room_num=r_name;
insert checkout(lodger_name,id_c,room_name,lives_days,room_account,back_change)
 values(name,id_d,r_name,days,days*price,pay_ment-days*price);
update date set p_checkout_date=ad_date where date.id=id_d;
end 
//
delimiter ;

delimiter //
drop procedure if exists p8_checkin;
create procedure p8_checkin(
l_name varchar(32),id varchar(18),r_name int,indate datetime,outdate datetime,pay int)
modifies sql data
begin
insert lodger values(l_name,id,r_name,pay);
insert date values(id,indate,outdate);
end
//
delimiter ;

delimiter //
drop procedure if exists p9_room;
create procedure p9_room(room int)
reads sql data
begin
select i.lodger_name,i.id_c,i.room_name,d.checkin_date,
d.p_checkout_date,i.lives_days,i.room_account,i.back_change
from date d,checkout i
where room=i.room_name and i.id_c=d.id;
end
//
delimiter ;

delimiter //
drop procedure if exists p10_profit;
create procedure p10_profit()
reads sql data
begin
select sum(room_account) as profit from checkout;
end
//
delimiter ;

drop user if exists administrator@localhost;
create user if not exists administrator@localhost identified by '1234';
grant all privileges on *.* to administrator@localhost; 


drop user if exists service@localhost;
create user service@localhost identified by '123456';
grant select,insert on *.* to service@localhost;




insert into room(room_num, room_type, room_price) values (101, 'single' ,100);
insert into room(room_num, room_type, room_price) values (102, 'double' ,200);
insert into room(room_num, room_type, room_price) values (103, 'single' ,100);
insert into room(room_num, room_type, room_price) values (104, 'double' ,200);
insert into room(room_num, room_type, room_price) values (201, 'single' ,100);
insert into room(room_num, room_type, room_price) values (202, 'double' ,200);
insert into room(room_num, room_type, room_price) values (203, 'single' ,100);
insert into room(room_num, room_type, room_price) values (204, 'double' ,200);
insert into room(room_num, room_type, room_price) values (301, 'single' ,100);
insert into room(room_num, room_type, room_price) values (302, 'double' ,200);
insert into room(room_num, room_type, room_price) values (303, 'single' ,100);
insert into room(room_num, room_type, room_price) values (304, 'double' ,200);
insert into room(room_num, room_type, room_price) values (401, 'single' ,100);
insert into room(room_num, room_type, room_price) values (402, 'double' ,200);
insert into room(room_num, room_type, room_price) values (403, 'single' ,100);
insert into room(room_num, room_type, room_price) values (404, 'double' ,200);




call p8_checkin('Ezio','18745253248278',101,'2021-11-29 21:42:16','2021-11-30 13:00:00',100);
call p8_checkin('Edward','13456151351561',102,'2021-11-29 18:35:25','2021-12-02 13:00:00',600);
call p8_checkin('Connor','97216168741876',103,'2021-11-29 19:25:45','2021-12-01 13:00:00',200);
call p8_checkin('Jacob','41775217137117',104,'2021-11-28 14:21:36','2021-11-29 13:00:00',200);
call p8_checkin('Arno','71896624124947',201,'2021-11-27 09:17:43','2021-11-29 13:00:00',300);
call p8_checkin('Bayek','54238921322782',202,'2021-11-28 20:42:29','2021-12-02 13:00:00',800);
call p8_checkin('Evie','64284278273272',301,'2021-11-28 16:37:48','2021-11-29 13:00:00',100);
call p8_checkin('Eivor','24828882713813',303,'2021-11-27 13:28:26','2021-11-29 13:00:00',200);
call p8_checkin('Altair','34271834144713',401,'2021-11-29 21:34:41','2021-12-01 13:00:00',200);
call p8_checkin('Desmond','22121287742543',402,'2021-11-27 21:49:28','2021-11-28 13:00:00',200);






call p7_checkout(102,3);
call p7_ad_checkout(101,'2021-11-30 15:25:14',1);
call p7_checkout(402,1);
call p7_checkout(303,2);
call p7_ad_checkout(401,'2021-12-01 12:42:29',2);
call p7_ad_checkout(104,'2021-11-29 19:15:47',1);
call p7_checkout(202,4);
call p7_ad_checkout(301,'2021-11-29 17:54:35',1);
call p7_ad_checkout(201,'2021-11-29 23:46:23',3);
call p7_checkout(103,2);







call p8_checkin('Rose','24565155154685',101,'2021-11-27 21:42:16','2021-11-28 13:00:00',100);
call p8_checkin('Matha','15369722515582',102,'2021-11-26 18:35:25','2021-11-29 13:00:00',600);
call p8_checkin('Donna','38284717672588',103,'2021-11-26 19:25:45','2021-11-28 13:00:00',200);
call p8_checkin('Amy','16457877264984',104,'2021-11-26 14:21:36','2021-11-27 13:00:00',200);
call p8_checkin('Clara','19631123202112',201,'2021-11-23 09:17:43','2021-11-26 13:00:00',300);
call p8_checkin('Bill','94848234326711',202,'2021-11-24 20:42:29','2021-11-28 13:00:00',800);
call p8_checkin('Raymond','12872821152643',301,'2021-11-26 16:37:48','2021-11-27 13:00:00',100);
call p8_checkin('Yaz','57222553414827',303,'2021-11-24 13:28:26','2021-11-26 13:00:00',200);
call p8_checkin('Dan','22534785215882',401,'2021-11-29 21:34:41','2021-12-01 13:00:00',200);
call p8_checkin('River','46585215824529',402,'2021-11-26 21:49:28','2021-11-27 13:00:00',200);







select *from room;
select *from lodger;
select *from checkout;



