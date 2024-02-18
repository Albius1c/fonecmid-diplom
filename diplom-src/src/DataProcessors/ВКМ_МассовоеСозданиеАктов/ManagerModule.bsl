#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область ПрограммныйИнтерфейс

// Код процедур и функций

#КонецОбласти

#Область ОбработчикиСобытий

// Код процедур и функций

#КонецОбласти

#Область СлужебныйПрограммныйИнтерфейс

// Код процедур и функций

#КонецОбласти

#Область СлужебныеПроцедурыИФункции
Функция ТяжелаяОперация(МесяцОтчета) Экспорт

	СписокДоговоров = СпискоДоговоровДляАктов(МесяцОтчета);

	Если СписокДоговоров.Пустой() Тогда
		ТекстШаблона = "За выбранный период данных нет";
		ОбщегоНазначения.СообщитьПользователю(ТекстШаблона);
		Возврат ТекстШаблона;
	Иначе
		ТаблицаДоговоров = СписокДоговоров.Выгрузить();
		МассивДанных = СоздатьДокументыРеализацияТоваровИУслуг(ТаблицаДоговоров, МесяцОтчета);
	КонецЕсли;

	Возврат МассивДанных;

КонецФункции

Функция СпискоДоговоровДляАктов(МесяцОтчета)

	Запрос = Новый Запрос;
	Запрос.Текст =
	"ВЫБРАТЬ
	|	РеализацияТоваровУслуг.Договор
	|ПОМЕСТИТЬ ВТ_ДокументРеализации
	|ИЗ
	|	Документ.РеализацияТоваровУслуг КАК РеализацияТоваровУслуг
	|ГДЕ
	|	РеализацияТоваровУслуг.Дата МЕЖДУ НАЧАЛОПЕРИОДА(&МесяцОтчета, Месяц) И КОНЕЦПЕРИОДА(&МесяцОтчета, Месяц)
	|	И НЕ РеализацияТоваровУслуг.ПометкаУдаления
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	ДоговорыКонтрагентов.Ссылка КАК Договор
	|ИЗ
	|	Справочник.ДоговорыКонтрагентов КАК ДоговорыКонтрагентов
	|ГДЕ
	|	ДоговорыКонтрагентов.ВМК_ДатаОкончания >= НАЧАЛОПЕРИОДА(&МесяцОтчета, Месяц)
	|	И НЕ ДоговорыКонтрагентов.ПометкаУдаления
	|	И НЕ ДоговорыКонтрагентов.Ссылка В
	|		(ВЫБРАТЬ
	|			ВТ_ДокументРеализации.Договор КАК Договор
	|		ИЗ
	|			ВТ_ДокументРеализации КАК ВТ_ДокументРеализации)
	|	И ДоговорыКонтрагентов.ВМК_ДатаНачала <= КОНЕЦПЕРИОДА(&МесяцОтчета, Месяц)";

	Запрос.УстановитьПараметр("МесяцОтчета", МесяцОтчета);

	Возврат Запрос.Выполнить();

КонецФункции

Функция СоздатьДокументыРеализацияТоваровИУслуг(ТаблицаДоговоров, МесяцОтчета)

	МассивДанных = Новый Массив;

	Для Каждого Док Из ТаблицаДоговоров Цикл

		ДокументМененджер = Документы.РеализацияТоваровУслуг.СоздатьДокумент();
		ДатаДокумента = ТекущаяДатаСеанса();
		ДокументМененджер.Дата = ?(ДатаДокумента > КонецМесяца(МесяцОтчета), КонецМесяца(МесяцОтчета), ДатаДокумента);
		ДокументМененджер.Организация = Док.Договор.Организация;
		ДокументМененджер.Контрагент = Док.Договор.Владелец;
		ДокументМененджер.Ответственный = Пользователи.ТекущийПользователь();
		ДокументМененджер.Основание = Док.Договор;
		ДокументМененджер.Комментарий = СтрШаблон("Услуги за период с %1 по %2", Формат(НачалоМесяца(МесяцОтчета),
			"ДФ=dd.MM.yyyy;"), Формат(КонецМесяца(МесяцОтчета), "ДФ=dd.MM.yyyy;"));
		ЗаполнитьЗначенияСвойств(ДокументМененджер, Док);
		ДокументМененджер.Записать(РежимЗаписиДокумента.Запись);
		ДокументМененджер.ВКМ_ВыполнитьАвтозаполнение();
		ДокументМененджер.Записать(РежимЗаписиДокумента.Запись);
		Если ДокументМененджер.ПроверитьЗаполнение() Тогда
			ДокументМененджер.Записать(РежимЗаписиДокумента.Проведение);
		Иначе
			ОбщегоНазначения.СообщитьПользователю(СтрШаблон("Не проведен. %1 не прошел проверку на заполнение",
				ДокументМененджер.Ссылка));
		КонецЕсли;

		МассивДанных.Добавить(ДокументМененджер.Ссылка);

	КонецЦикла;

	Возврат МассивДанных;

КонецФункции

#КонецОбласти

#КонецЕсли