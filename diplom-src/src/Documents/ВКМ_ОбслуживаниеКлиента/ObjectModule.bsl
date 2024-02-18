#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область ОписаниеПеременных

#КонецОбласти

#Область ПрограммныйИнтерфейс

// Код процедур и функций

#КонецОбласти

#Область ОбработчикиСобытий
Процедура ПриЗаписи(Отказ)
	Если ОбменДанными.Загрузка Тогда
		Возврат;
	КонецЕсли;

	ПодготвитьСообщениеДляОповещенияТелеграмм();

КонецПроцедуры

Процедура ОбработкаПроведения(Отказ, Режим)

	Если ВыполненныеРаботы.Итог("ЧасыКОплатеКлиенту") = 0 Тогда
		ОбщегоНазначения.СообщитьПользователю("Незаполнена табличная часть выполненные работы.");
		Отказ = Истина;
	КонецЕсли;
	Запрос = Новый Запрос;
	Запрос.Текст =
	"ВЫБРАТЬ
	|	ВКМ_ОбслуживаниеКлиента.Ссылка,
	|	ВКМ_ОбслуживаниеКлиента.Дата,
	|	ВКМ_ОбслуживаниеКлиента.Договор,
	|	СУММА(ЕСТЬNULL(ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы.ЧасыКОплатеКлиенту, 0)) КАК ЧасыКОплатеКлиенту,
	|	ВКМ_УсловияОплатыСотрудниковСрезПоследних.ПроцентОтРабот
	|ПОМЕСТИТЬ ВТ_Документ
	|ИЗ
	|	Документ.ВКМ_ОбслуживаниеКлиента КАК ВКМ_ОбслуживаниеКлиента
	|		ЛЕВОЕ СОЕДИНЕНИЕ Документ.ВКМ_ОбслуживаниеКлиента.ВыполненныеРаботы КАК ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы
	|		ПО ВКМ_ОбслуживаниеКлиентаВыполненныеРаботы.Ссылка = ВКМ_ОбслуживаниеКлиента.Ссылка
	|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.ВКМ_УсловияОплатыСотрудников.СрезПоследних(&Дата, Сотрудник = &Специалист) КАК
	|			ВКМ_УсловияОплатыСотрудниковСрезПоследних
	|		ПО ВКМ_ОбслуживаниеКлиента.Специалист = ВКМ_УсловияОплатыСотрудниковСрезПоследних.Сотрудник
	|ГДЕ
	|	ВКМ_ОбслуживаниеКлиента.Ссылка = &Ссылка
	|СГРУППИРОВАТЬ ПО
	|	ВКМ_ОбслуживаниеКлиента.Дата,
	|	ВКМ_ОбслуживаниеКлиента.Ссылка,
	|	ВКМ_ОбслуживаниеКлиента.Договор,
	|	ВКМ_УсловияОплатыСотрудниковСрезПоследних.ПроцентОтРабот
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	ВТ_Документ.Ссылка,
	|	ВТ_Документ.Дата,
	|	ВТ_Документ.Договор,
	|	ВТ_Документ.ЧасыКОплатеКлиенту,
	|	ДоговорыКонтрагентов.ВМК_ДатаНачала КАК ДатаНачала,
	|	ДоговорыКонтрагентов.ВМК_ДатаОкончания КАК ДатаОкончания,
	|	ДоговорыКонтрагентов.ВМК_СтоимостьЧасаРаботы КАК СтоимостьЧасаРаботы,
	|	ВЫБОР
	|		КОГДА ВТ_Документ.Дата МЕЖДУ НАЧАЛОПЕРИОДА(ДоговорыКонтрагентов.ВМК_ДатаНачала,
	|			День) И КОНЕЦПЕРИОДА(ДоговорыКонтрагентов.ВМК_ДатаОкончания, День)
	|			ТОГДА ЛОЖЬ
	|		ИНАЧЕ ИСТИНА
	|	КОНЕЦ КАК Отказ,
	|	ВТ_Документ.ПроцентОтРабот
	|ИЗ
	|	ВТ_Документ КАК ВТ_Документ
	|		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.ДоговорыКонтрагентов КАК ДоговорыКонтрагентов
	|		ПО ВТ_Документ.Договор = ДоговорыКонтрагентов.Ссылка";

	Запрос.УстановитьПараметр("Ссылка", Ссылка);
	Запрос.УстановитьПараметр("Дата", Дата);
	Запрос.УстановитьПараметр("Специалист", Специалист);

	Выборка = Запрос.Выполнить().Выбрать();

	Пока Выборка.Следующий() Цикл

		Если Выборка.Отказ Тогда
			ТекстСообщения = СтрШаблон(
			"Запрет на проведение документа. Дата обращения %1 не соответствует согласованному периоду по договору %2",
				Дата, Договор);
			ОбщегоНазначения.СообщитьПользователю(ТекстСообщения);
			Отказ = Истина;
			Продолжить;
		КонецЕсли;	
		
		// регистр ВыполненныеКлиентуРаботы
		Движения.ВыполненныеКлиентуРаботы.Записывать = Истина;
		Движение = Движения.ВыполненныеКлиентуРаботы.Добавить();
		Движение.Период = Дата;
		Движение.ВидДвижения = ВидДвиженияНакопления.Расход;
		Движение.Клиент = Клиент;
		Движение.Договор = Договор;
		Движение.КоличествоЧасов = Выборка.ЧасыКОплатеКлиенту;
		Движение.СуммаКОплате = Движение.КоличествоЧасов * Выборка.СтоимостьЧасаРаботы;

		Если Выборка.ПроцентОтРабот >= 0 Тогда
			// регистр ВыполненныеСотрудникомРаботы
			Движения.ВКМ_ВыполненныеСотрудникомРаботы.Записывать = Истина;
			Движение = Движения.ВКМ_ВыполненныеСотрудникомРаботы.Добавить();
			Движение.Период = Дата;
			Движение.Сотрудник = Специалист;
			Движение.ЧасовКОплате = Выборка.ЧасыКОплатеКлиенту;
			Движение.СуммаКОплате = Движение.ЧасовКОплате * Выборка.СтоимостьЧасаРаботы * Выборка.ПроцентОтРабот / 100;
		Иначе
			ОбщегоНазначения.СообщитьПользователю(
				"Сведения о работе сотрудника %1 незаписаны. Нужно установить условия опалты в процентах.",
				Выборка.Сотрудник);
			Отказ = Истина;
		КонецЕсли;

	КонецЦикла;

КонецПроцедуры// Код процедур и функций

#КонецОбласти

#Область СлужебныйПрограммныйИнтерфейс

// Код процедур и функций

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Процедура ПодготвитьСообщениеДляОповещенияТелеграмм()

	НомерБезНулей= СтрЗаменить(СокрЛ(СтрЗаменить(Номер, 0, " ")), " ", 0);

	Если ВыполненныеРаботы.Итог("ЧасыКОплатеКлиенту") > 0 Тогда

		ШаблонСообщения = СтрШаблон(
		"Заявка №%1 от %2. Специалист %3. Запланировано %4ч. выполнено %5ч.", НомерБезНулей, Формат(Дата, "ДЛФ=D;"),
			Специалист, Формат(ВыполненныеРаботы.Итог("ФактическиПотраченоЧасов"), "ЧН=Ноль;"), ВыполненныеРаботы.Итог(
			"ЧасыКОплатеКлиенту"));

	Иначе
		ШаблонСообщения = СтрШаблон(
		"Заявка №%1 от %2. Специалист %3. Дата и время проведения работ %4 с %5", НомерБезНулей, Формат(Дата, "ДЛФ=D;"),
			Специалист, Формат(ДатаПроведенияРабот, "ДФ=dd.MM.yyyy;"), Формат(ВремяНачалаРабот, "ДЛФ=T;"));

	КонецЕсли;

	Если ЭтоНовый() Тогда
		СоздатьНовыйЭлементСправочникУведомленияТелеграмБоту(ШаблонСообщения);
		Возврат;
	КонецЕсли;

	Запрос = Новый Запрос;
	Запрос.Текст =
	"ВЫБРАТЬ
	|	ВКМ_УведомленияТелеграмБоту.ТекстСообщения,
	|	ВКМ_УведомленияТелеграмБоту.ВерсияДанных
	|ИЗ
	|	Справочник.ВКМ_УведомленияТелеграмБоту КАК ВКМ_УведомленияТелеграмБоту
	|ГДЕ
	|	ВКМ_УведомленияТелеграмБоту.Наименование = &Номер";

	Запрос.УстановитьПараметр("Номер", Номер);

	Выборка = Запрос.Выполнить().Выбрать();
	Если Выборка.Следующий() Тогда
		ТекстСообщения = Выборка.ТекстСообщения;
	КонецЕсли;

	Если ТекстСообщения <> ШаблонСообщения Тогда

		ТекущийЭлемент = Справочники.ВКМ_УведомленияТелеграмБоту.НайтиПоНаименованию(Номер, Истина);
		Если Не ЗначениеЗаполнено(ТекущийЭлемент) Тогда
			СоздатьНовыйЭлементСправочникУведомленияТелеграмБоту(ШаблонСообщения);
		Иначе
			ОбъектЭлемента = ТекущийЭлемент.ПолучитьОбъект();
			ОбъектЭлемента.ТекстСообщения = ШаблонСообщения;
			ОбъектЭлемента.Записать();
		КонецЕсли;
	КонецЕсли;

КонецПроцедуры

Процедура СоздатьНовыйЭлементСправочникУведомленияТелеграмБоту(ШаблонСообщения)
	НовыйЭлемент = Справочники.ВКМ_УведомленияТелеграмБоту.СоздатьЭлемент();
	НовыйЭлемент.Наименование = Номер;
	НовыйЭлемент.ТекстСообщения = ШаблонСообщения;
	НовыйЭлемент.Записать();
КонецПроцедуры

Функция КонтрольУстановкиПроцентаОплатыОтРабот(Сотрудник, ДатаДокумента)

	Запрос = Новый Запрос;
	Запрос.Текст =
	"ВЫБРАТЬ
	|	ВКМ_УсловияОплатыСотрудниковСрезПоследних.Сотрудник.Представление КАК Сотрудник,
	|	ВКМ_УсловияОплатыСотрудниковСрезПоследних.ПроцентОтРабот
	|ИЗ
	|	РегистрСведений.ВКМ_УсловияОплатыСотрудников.СрезПоследних(&ДатаДокумента, Сотрудник = &Сотрудник) КАК
	|		ВКМ_УсловияОплатыСотрудниковСрезПоследних";

	Запрос.УстановитьПараметр("ДатаДокумента", ДатаДокумента);
	Запрос.УстановитьПараметр("Сотрудник", Сотрудник);

	Выборка = Запрос.Выполнить().Выбрать();

	Если Выборка.Следующий() Тогда
		Если Выборка.ПроцентОтРабот >= 0 Тогда
			Возврат Истина;
		Иначе
			ОбщегоНазначения.СообщитьПользователю(
				"Сведения о работе сотрудника %1 незаписаны. Нужно установить условия опалты в процентах.");
		КонецЕсли;
	КонецЕсли;

	Возврат Ложь;

КонецФункции

#КонецОбласти

#Область Инициализация

#КонецОбласти

#КонецЕсли