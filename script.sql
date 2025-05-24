use SimpleOne

set datefirst 1

declare
--@dbeg as date,
--@dend as date,
@agobeg as date,
@agoend as date

--set @dbeg = '2024-11-01'
--set @dend = '2024-11-30'
set @agobeg = cast(dateadd(mm,datediff(mm,0,@dbeg)-3,0) as date) 
set @agoend = DATEADD(day, -1,@dbeg)

-- отпуска в периоде
select full_name as "ФИО"
,Email
,count([Рабочий день]) as [Количество дней в отпуске в промежутке]
into #t1
from SimpleOne.dbo.ZUP_ders_absence_empl_servionika as zup
left join [dbo].[Calendar](@dbeg,@dend)  as calend on calend.DateSeq between zup.date_start and zup.date_end and calend.[Рабочий день] = 'Рабочий'
where (month(date_start)=month(@dbeg) or month(date_end) = month(@dend)  or
(date_start < @dbeg and (date_end > @dend or date_end = '0001-01-01')))
and condition <> 'Командировка' and job_type <>'ВнутреннееСовместительство'
group by full_name,Email

-- отпуска для высчитывание среднего
select full_name as "ФИО"
,Email
,count([Рабочий день]) as [Количество дней в отпуске за три месяца]
into #t11
from SimpleOne.dbo.ZUP_ders_absence_empl_servionika as zup
left join [dbo].[Calendar](@agobeg,@agoend)  as calend on calend.DateSeq between zup.date_start and zup.date_end and calend.[Рабочий день] = 'Рабочий'
where (month(date_start)=month(@agobeg) or month(date_end) = month(@agoend)  or
(date_start < @agobeg and (date_end > @agoend or date_end = '0001-01-01')))
and condition <> 'Командировка' and job_type <>'ВнутреннееСовместительство'
group by full_name,Email

-- отбор сотрудников 
select Emp.c_fio 
,emp.email
,Emp.sys_id
,Emp.c_department
,Emp.c_management
,Emp.c_branch 
,Emp.c_group
,Emp.c_fifth_level_unit 
,Emp.c_direct_manager
,Emp.c_func_manager
,[Количество ставок]
,[Дата приема]
,[Дата завершения работы]
,[Дата начала периода для каждого сотрудника] 
,[Дата окончания периода для каждого сотрудника]
,isnull([Количество дней в отпуске в промежутке],0) as [Количество дней в отпуске в промежутке]
,isnull([Количество дней в отпуске за три месяца],0)  as [Количество дней в отпуске за три месяца]

,count(iif(calend.DateSeq between Emp.[Дата начала периода для каждого сотрудника] and Emp.[Дата окончания периода для каждого сотрудника]
        ,calend.DateSeq,NULL)) as [Количество рабочих дней промежутке для сотрудника]

,count(iif(calend.DateSeq between Emp.[Дата начала трехмесячного периода для каждого сотрудника]  
and Emp. [Дата окончания трехмесячного периода для каждого сотрудника] ,calend.DateSeq,NULL)) as [Количество рабочих дней за три месяца]

,count(iif(calend.DateSeq between Emp.[Дата начала периода для каждого сотрудника] and Emp.[Дата окончания периода для каждого сотрудника],calend.DateSeq,NULL))
     - isnull([Количество дней в отпуске в промежутке],0) as [Итоговое количество рабочих дней]

,count(iif(calend.DateSeq between Emp.[Дата начала трехмесячного периода для каждого сотрудника]  
and Emp. [Дата окончания трехмесячного периода для каждого сотрудника] ,calend.DateSeq,NULL)) 
- isnull([Количество дней в отпуске за три месяца],0) as [Итоговое количество рабочих дней за три месяца]
into #t2
from (
select c_fio 
,Emp.email
,Emp_1c.[Дата приема]
,Emp_1c.[Дата завершения работы]
,Emp.sys_id
,Emp.c_department
,Emp.c_management
,Emp.c_branch 
,Emp.c_group
,Emp.c_fifth_level_unit 
,Emp.c_direct_manager
,Emp.c_func_manager
,case 
when Emp_1c.[Дата приема] is null then @dbeg
when @dbeg < cast(Emp_1c.[Дата приема] as date) then cast(Emp_1c.[Дата приема] as date)
when @dbeg >= cast(Emp_1c.[Дата приема] as date)  then @dbeg
else NULL end as [Дата начала периода для каждого сотрудника] 

,case 
when Emp_1c.[Дата завершения работы] is null then @dend
when @dend < cast(Emp_1c.[Дата завершения работы] as date) then @dend
when @dend >= cast(Emp_1c.[Дата завершения работы] as date) then cast(Emp_1c.[Дата завершения работы] as date)
else NULL end as [Дата окончания периода для каждого сотрудника] 
,Emp_1c.[Количество ставок]+ isnull(Emp_1c_int.[Количество ставок],0) as [Количество ставок]

,case 
when Emp_1c.[Дата приема] is null then @agobeg
when @agobeg < cast(Emp_1c.[Дата приема] as date) then cast(Emp_1c.[Дата приема] as date)
when @agobeg >= cast(Emp_1c.[Дата приема] as date)  then @agobeg
else NULL end as [Дата начала трехмесячного периода для каждого сотрудника] 

,case 
when Emp_1c.[Дата завершения работы] is null then @agoend
when @agoend < cast(Emp_1c.[Дата завершения работы] as date) then @agoend
when @agoend >= cast(Emp_1c.[Дата завершения работы] as date) then cast(Emp_1c.[Дата завершения работы] as date)
else NULL end as [Дата окончания трехмесячного периода для каждого сотрудника] 

from SimpleOne.dbo.employee as Emp
join SimpleOne.dbo.employee_1c as Emp_1c on Emp.email = rtrim(ltrim(Emp_1c.email))  and [Вид занятости] <> 'ВнутреннееСовместительство'
left join SimpleOne.dbo.employee_1c as Emp_1c_int on Emp.email = rtrim(ltrim(Emp_1c_int.email)) and Emp_1c_int.[Вид занятости] = 'ВнутреннееСовместительство' and Emp_1c_int.[Состояние] <>'Увольнение'

left JOIN SimpleOne.dbo.org_unit AS P1                   ON P1.sys_id = Emp.c_department 
left JOIN SimpleOne.dbo.org_unit AS P2                   ON P2.sys_id = Emp.c_management 
left JOIN SimpleOne.dbo.org_unit AS P3                   ON P3.sys_id = Emp.c_branch 
left JOIN SimpleOne.dbo.org_unit AS P4                   ON P4.sys_id = Emp.c_group 
left JOIN SimpleOne.dbo.org_unit AS P5                   ON P5.sys_id = Emp.c_fifth_level_unit 
where Emp.company = 161839148291664998 and  Emp.c_contact_type = 'internal' and
cast(isnull(CONVERT(date, Emp_1c.[Дата приема], 104),@dbeg) as date) <= @dend and cast(isnull(CONVERT(date, Emp_1c.[Дата завершения работы], 104),@dend) as date)>= @dbeg
and Emp_1c.[Состояние] not in ('ОтпускПоБеременностиИРодам','ОтпускПоУходуЗаРебенком','ТрудовойДоговорПриостановлен')
and c_fio not in ('1С Интеграция ','Service ОВК ')
and isnull(P1.name,'Не указано') in (@department1) 
and isnull(P2.name,'Не указано') in (@department2) 
and isnull(P3.name,'Не указано') in (@department3) 
and isnull(P4.name,'Не указано') in (@department4) 
and isnull(P5.name,'Не указано') in (@department5) 
) as Emp
left join [dbo].[Calendar](@agobeg,@dend)  as calend on calend.DateSeq between Emp.[Дата начала трехмесячного периода для каждого сотрудника] 
and Emp.[Дата окончания периода для каждого сотрудника] and calend.[Рабочий день] = 'Рабочий'
left join #t1 on Emp.c_fio = #t1.[ФИО]
left join #t11 on Emp.c_fio = #t11.[ФИО]
group by Emp.c_fio
,emp.email
,Emp.sys_id
,Emp.c_department
,Emp.c_management
,Emp.c_branch 
,Emp.c_group
,Emp.c_fifth_level_unit 
,Emp.c_direct_manager
,Emp.c_func_manager
,[Количество ставок]
,[Дата приема]
,[Дата завершения работы]
,[Дата начала периода для каждого сотрудника] 
,[Дата окончания периода для каждого сотрудника]
,[Количество дней в отпуске в промежутке]
,[Количество дней в отпуске за три месяца]
 OPTION (MAXRECURSION 150)


SELECT 'SO' as 'Система'
, case when left(isnull(T2.number,T0.number),3) = 'REQ' then 'Заявка' 
       when left(isnull(T2.number,T0.number),3) = 'RQT' then 'Наряд' 
       when T1.external_number is not null then 'Внеш.система' 
	   else 'Активность' end as Объект
, case when T1.task is not null then isnull(T2.number,T0.number)
       when T1.external_number is not null then T1.external_number
	   else A1.number 
	   end as ID
, dateadd(hour,3,isnull(T2.opened_at,T0.opened_at)) as 'Создано'
, dateadd(hour,3,isnull(T2.resolved_at,T0.resolved_at)) AS 'Выполнено'
, dateadd(hour,3,isnull(T2.Deadline,T0.Deadline)) as 'Предельный срок'
, dateadd(hour,3,isnull(date_of_work,T1.sys_created_at)) as 'Дата работы'
, case when (T1.approval is null or T1.approval = 2) then ROUND(CAST(isnull(T1.time_of_work,0) as numeric)/3600000,2) 
+ ROUND(CAST(isnull(T1.travel_time,0) as numeric)/3600000,2) + isnull(extracurricular_activities_hours,0)
      else 0 end as 'Трудозатраты ч'
, case when T1.extracurricular_work = 0 and (T1.approval in (2,4) OR T1.approval is null) then ROUND(CAST(isnull(T1.time_of_work,0) as numeric)/3600000,2) 
when T1.extracurricular_work = 0 and T1.approval in (1,3,5) then isnull(time_of_work_hours,0) + (isnull(time_of_work_minutes,0)/60)
      else 0 end as 'Рабочие ч' 
, case when T1.extracurricular_work = 1 and (T1.approval is null or T1.approval in (2,4)) 
then ROUND(CAST(isnull(T1.time_of_work,0) as numeric)/3600000,2) + isnull(extracurricular_activities_hours,0)
     	when T1.extracurricular_work = 1 and T1.approval in (1,3,5) then isnull(extracurricular_activities_hours,0)
      else 0 end as 'Нерабочие ч' 
,ROUND(CAST(isnull(T1.travel_time,0) as numeric)/3600000,2) as 'В дороге ч'
, Work_Start as 'Начало переработок'
, Work_End as 'Окончание переработок'
, G3.[name] AS 'Рабочая группа'
,case 
when Emp.sys_id = 164492092297345094 then concat(LTRIM(RTRIM(Emp.c_fio)),' ЦФО')
when Emp.sys_id = 164492057096435865 then concat(LTRIM(RTRIM(Emp.c_fio)),' СФО')
when Emp.sys_id = 169994673906290133 then concat(LTRIM(RTRIM(Emp.c_fio)),' ПФО')
when Emp.sys_id = 164493713798822638 then concat(LTRIM(RTRIM(Emp.c_fio)),' ДФО')
else LTRIM(RTRIM(Emp.c_fio)) end  as 'Исполнитель'  
, case when C1.[name] is null then C2.[name] 
       else C1.[name] end AS 'Организация'
, case when A1.activity_name is null then A2.activity_name 
       else A1.activity_name end AS 'Активность'
, case when B1.Budget is null then B2.Budget 
       else isnull(B1.Budget,'<Отсутствует>') end AS 'Бюджет'
, T1.result AS 'Рабочие заметки'
,iif(Emp.sys_id in (167654296097304207,164492216792074731,164492174593583700,164492085094886196),'Дирекция сервиса децентрализованных систем', P1.[name]) 
	                                      AS [Подразделение 1-го уровня]
,iif(Emp.sys_id in (167654296097304207,164492216792074731,164492174593583700,164492085094886196),P1.[name],P2.[name])
	                                      AS [Подразделение 2-го уровня]
,iif(Emp.sys_id in (167654296097304207,164492216792074731,164492174593583700,164492085094886196),P2.[name],P3.[name])                        
	                                      AS [Подразделение 3-го уровня]
,iif(Emp.sys_id in (167654296097304207,164492216792074731,164492174593583700,164492085094886196),P3.[name],P4.[name])
	                                      AS [Подразделение 4-го уровня]
,P5.[name]                         AS [Подразделение 5-го уровня]
,concat('https://sd.servionica.ru/record/itsm_tchnsrv_time_report/',T1.sys_id) as URL
,case 
     when state_approval = 'approval' then 'Согласование'
	 when state_approval = 'rejected_by_supervisor' then 'Отклонен Руководителем'
	 when state_approval = 'cancelled' then 'Отозван'
	 when state_approval = 'approval_project_manager' then 'Согласование с РП'
	 when state_approval = 'approved_project_manager' then 'Согласован РП'
	 when state_approval = 'rejected_project_manager' then 'Отклонен РП'
	 when state_approval = 'repealed' then 'Аннулирован'
	 when state_approval = 're_approval_with_project_manager' then 'Повторное согласование с РП'
         when state_approval is null  then 'Не требует согласования'
	 else state_approval 
	 end as "Статус согласования"
,T1.approval as [Согласование]
,[Количество дней в отпуске в промежутке]
,[Количество рабочих дней промежутке для сотрудника]
,[Итоговое количество рабочих дней]
,[Итоговое количество рабочих дней за три месяца]
,Emp_func.c_fio as "Функциональный руководитель"
,Emp_direct.c_fio as "Непосредственный руководитель"
,[Количество ставок]
,concat('https://sd.servionica.ru/record/employee/',Emp.sys_id)as URL_employee

,case when (
(T1.task is not null and cast(DATEADD(hh,3,T1.sys_created_at) as date) between @dbeg AND @dend)
OR (state_approval is not null and cast(DATEADD(hh,3,T1.date_of_work) as date) between @dbeg AND @dend)
OR (state_approval is null and T1.task is null and isnull(T1.[year],calend.year) = year(@dend) and (calend.[month] + 1) =  month(@dend))
OR (state_approval is null and T1.task is null and calend.[month] is null 
    and cast(DATEADD(hh,3,T1.date_of_work) as date) between @dbeg AND @dend)
)
then 'Да' else 'Нет' end as [Нужный период]

,case when (
(T1.task is not null and cast(DATEADD(hh,3,T1.sys_created_at) as date) between @agobeg AND @agoend)
OR (state_approval is not null and cast(DATEADD(hh,3,T1.date_of_work) as date) between @agobeg AND @agoend)
OR (state_approval is null and T1.task is null and calend.[month] is null 
    and cast(DATEADD(hh,3,T1.date_of_work) as date) between @agobeg AND @agoend)
	)
then 'Да' else 'Нет' end as [Трехмесячный период]

,case when (state_approval = 'approved_project_manager' or state_approval is null) and T1.approval in (2,4) 
then 'Да' else 'Нет' end as [Общий статус согласования]

,case
 when T1.external_number is not null then cast(T1.sys_id as nvarchar)
 when T1.task is not null and ABS(datediff(minute,isnull(T2.resolved_at,T0.resolved_at),T1.sys_created_at)) <= 1
 then isnull(T2.number,T0.number)
 else Null end as [Признак выполнения заявки]
,case
 when left(isnull(T2.number,T0.number),3) = 'REQ' then concat('https://sd.servionica.ru/record/itsm_request/',T2.sys_id)
 when left(isnull(T2.number,T0.number),3) = 'RQT' then concat('https://sd.servionica.ru/record/itsm_request_task/',T0.sys_id)
 else  NULL end as URL_REQ
 ,case when ((state_approval in ('approval','approval_project_manager','approved_project_manager','re_approval_with_project_manager')
or state_approval is null) and T1.approval <> 5) 
then 'Да' else 'Нет' end as [Промежуточный статус согласования]
FROM #t2 AS Emp 
left join SimpleOne.dbo.itsm_tchnsrv_time_report AS T1 ON Emp.sys_id = T1.person
left join SimpleOne.dbo.itsm_request AS T2 ON T2.sys_id = T1.task
left join SimpleOne.dbo.itsm_request_task AS T0 ON T0.sys_id = T1.task
left join SimpleOne.dbo.itsm_request AS T3 ON T3.sys_id = T0.related_task
left join SimpleOne.dbo.employee AS Emp_ini ON Emp_ini.sys_id = isnull(T2.initiator,T0.initiator)
left join SimpleOne.dbo.employee as Emp_func on Emp.c_func_manager = Emp_func.sys_id
left join SimpleOne.dbo.employee as Emp_direct on Emp.c_direct_manager = Emp_direct.sys_id

left join SimpleOne.dbo.itsm_tchnsrv_activity AS A1 ON A1.sys_id = T1.acticvity 
left join SimpleOne.dbo.itsm_tchnsrv_activity AS A2 ON A2.sys_id = isnull(T2.activity,T3.activity)
left join SimpleOne.dbo.org_company AS C1 ON C1.sys_id = A1.client_organization
left join SimpleOne.dbo.org_company AS C2 ON C2.sys_id = isnull(T2.company,T3.company)
left join SimpleOne.dbo.itsm_tchnsrv_budget AS B1 ON B1.sys_id = A1.budget_number
left join SimpleOne.dbo.itsm_tchnsrv_budget AS B2 ON B2.sys_id = A2.budget_number--
left join SimpleOne.dbo.sys_group AS G3 ON isnull(T2.assignment_group,T0.assignment_group) = G3.sys_id 
left join SimpleOne.dbo.itsm_tchnsrv_production_calendar as calend on calend.sys_id = T1.[month] 

left JOIN SimpleOne.dbo.org_unit AS P1                   ON P1.sys_id = Emp.c_department 
left JOIN SimpleOne.dbo.employee as E1                   on P1.unit_head = E1.sys_id
left JOIN SimpleOne.dbo.org_unit AS P2                   ON P2.sys_id = Emp.c_management 
left JOIN SimpleOne.dbo.employee as E2                   on P2.unit_head = E2.sys_id
left JOIN SimpleOne.dbo.org_unit AS P3                   ON P3.sys_id = Emp.c_branch 
left JOIN SimpleOne.dbo.employee as E3                   on P3.unit_head = E3.sys_id
left JOIN SimpleOne.dbo.org_unit AS P4                   ON P4.sys_id = Emp.c_group 
left JOIN SimpleOne.dbo.employee as E4                   on P4.unit_head = E4.sys_id
left JOIN SimpleOne.dbo.org_unit AS P5                   ON P5.sys_id = Emp.c_fifth_level_unit 
left JOIN SimpleOne.dbo.employee as E5                   on P5.unit_head = E5.sys_id

WHERE ((T1.task is not null and cast(DATEADD(hh,3,T1.sys_created_at) as date) between @agobeg AND @dend) --Списание в Simple
OR (state_approval is not null and cast(DATEADD(hh,3,T1.date_of_work) as date) between @agobeg AND @dend) --Списание внешних по новому модулю
OR (state_approval is null and T1.task is null and isnull(T1.[year],calend.year) = year(@dend) and (calend.[month] + 1) =  month(@dend)) --Списание РП на активность
OR (state_approval is null and T1.task is null and calend.[month] is null 
    and cast(DATEADD(hh,3,T1.date_of_work) as date) between @agobeg AND @dend)) --Списание через Excel

union all

select 
'SO' as 'Система'
,'Нет списаний' as Объект
,NULL as ID
,NULL as 'Создано'
,NULL AS 'Выполнено'
,NULL as 'Предельный срок'
,NULL as 'Дата работы'
,0 as 'Трудозатраты ч'
,0 as 'Рабочие ч' 
,0 as 'Нерабочие ч'
,0 as 'В дороге ч'
,NULL as 'Начало переработок'
,NULL as 'Окончание переработок'
,NULL AS 'Рабочая группа'
,case 
when Emp.sys_id = 164492092297345094 then concat(LTRIM(RTRIM(Emp.c_fio)),' ЦФО')
when Emp.sys_id = 164492057096435865 then concat(LTRIM(RTRIM(Emp.c_fio)),' СФО')
when Emp.sys_id = 169994673906290133 then concat(LTRIM(RTRIM(Emp.c_fio)),' ПФО')
when Emp.sys_id = 164493713798822638 then concat(LTRIM(RTRIM(Emp.c_fio)),' ДФО')
else LTRIM(RTRIM(Emp.c_fio)) end  as 'Исполнитель'  
, NULL AS 'Организация'
, NULL AS 'Активность'
, NULL AS 'Бюджет'
, NULL AS 'Рабочие заметки'
,iif(Emp.sys_id in (167654296097304207,164492216792074731,164492174593583700,164492085094886196),'Дирекция сервиса децентрализованных систем', P1.[name]) 
	                                      AS [Подразделение 1-го уровня]
,iif(Emp.sys_id in (167654296097304207,164492216792074731,164492174593583700,164492085094886196),P1.[name],P2.[name])
	                                      AS [Подразделение 2-го уровня]
,iif(Emp.sys_id in (167654296097304207,164492216792074731,164492174593583700,164492085094886196),P2.[name],P3.[name])                        
	                                      AS [Подразделение 3-го уровня]
,iif(Emp.sys_id in (167654296097304207,164492216792074731,164492174593583700,164492085094886196),P3.[name],P4.[name])
	                                      AS [Подразделение 4-го уровня]
,P5.[name]                         AS [Подразделение 5-го уровня]
,NULL as URL
,'Не требует согласования' as "Статус согласования"
,'Не требует согласования' as [Согласование]

,[Количество дней в отпуске в промежутке]
,[Количество рабочих дней промежутке для сотрудника]
,[Итоговое количество рабочих дней]
,[Итоговое количество рабочих дней за три месяца]
,Emp_func.c_fio as "Функциональный руководитель"
,Emp_direct.c_fio as "Непосредственный руководитель"
,[Количество ставок]
,concat('https://sd.servionica.ru/record/employee/',Emp.sys_id)as URL_employee
,'Да' as [Нужный период]
,'Нет' as [Трехмесячный период]
,'Да' as [Общий статус согласования]
,Null as [Признак выполнения заявки]
,NULL as URL_REQ
,'Да' as [Промежуточный статус согласования]
from #t2 AS Emp
left join SimpleOne.dbo.employee as Emp_func on Emp.c_func_manager = Emp_func.sys_id
left join SimpleOne.dbo.employee as Emp_direct on Emp.c_direct_manager = Emp_direct.sys_id
left JOIN SimpleOne.dbo.org_unit AS P1                   ON P1.sys_id = Emp.c_department 
left JOIN SimpleOne.dbo.employee as E1                   on P1.unit_head = E1.sys_id
left JOIN SimpleOne.dbo.org_unit AS P2                   ON P2.sys_id = Emp.c_management 
left JOIN SimpleOne.dbo.employee as E2                   on P2.unit_head = E2.sys_id
left JOIN SimpleOne.dbo.org_unit AS P3                   ON P3.sys_id = Emp.c_branch 
left JOIN SimpleOne.dbo.employee as E3                   on P3.unit_head = E3.sys_id
left JOIN SimpleOne.dbo.org_unit AS P4                   ON P4.sys_id = Emp.c_group 
left JOIN SimpleOne.dbo.employee as E4                   on P4.unit_head = E4.sys_id
left JOIN SimpleOne.dbo.org_unit AS P5                   ON P5.sys_id = Emp.c_fifth_level_unit 
left JOIN SimpleOne.dbo.employee as E5                   on P5.unit_head = E5.sys_id

where Emp.sys_id not in 
(select distinct person 
from SimpleOne.dbo.itsm_tchnsrv_time_report as T1
left join SimpleOne.dbo.itsm_tchnsrv_production_calendar as calend on calend.sys_id = T1.[month] 
left join SimpleOne.dbo.employee AS Emp                  ON Emp.sys_id = T1.person
left JOIN SimpleOne.dbo.org_unit AS P1                   ON P1.sys_id = Emp.c_department 
WHERE --здесь необходимо исключить и добавить только сотрудников работающих на отчетный период.
(
((T1.task is not null and cast(DATEADD(hh,3,T1.sys_created_at) as date) between @dbeg AND @dend)--Списание по заявкам
OR (state_approval is not null and cast(DATEADD(hh,3,T1.date_of_work) as date) between @dbeg AND @dend)--Списание на внешние системы через SO
OR (state_approval is null and T1.task is null and isnull(T1.[year],calend.year) = year(@dend) and (calend.[month] + 1) =  month(@dend))) --Списание на активность
OR (state_approval is null and T1.task is null and calend.[month] is null 
    and cast(DATEADD(hh,3,T1.date_of_work) as date) between @dbeg AND @dend)) --Списание через Excel, добавлено 15.05
and person is not null)


drop table #t1
drop table #t11
drop table #t2
