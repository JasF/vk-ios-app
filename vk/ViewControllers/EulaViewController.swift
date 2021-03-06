//
//  EulaViewController.swift
//  Oxy Feed
//
//  Created by Jasf on 21.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import DOCheckboxControl

@objcMembers class EulaViewController : UIViewController, UITextViewDelegate {
    @IBOutlet var textView: UITextView?
    var appeared = false
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        self.view.backgroundColor = UIColor.white
        self.navigationController?.navigationBar.barStyle = .blackTranslucent
        guard let textView = textView else { return }
        textView.attributedText = NSAttributedString(string: eulaString, attributes: TextStyles.eulaOnlyTextStyle())
        textView.showsHorizontalScrollIndicator = false;
        textView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        appeared = true
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if appeared == false {
            scrollView.contentOffset = CGPoint(x:0,y:0)
        }
    }
    
    let eulaString = """
Политика Конфиденциальности

1. Общие положения
1.1. Настоящие Правила являются официальным документом  и определяют порядок обработки и защиты информации о физических лицах, пользующихся услугами сервиса.
1.2. Целью настоящих Правил является обеспечение надлежащей защиты информации о пользователях, в том числе их персональных данных, от несанкционированного доступа и разглашения.
1.3. Отношения, связанные со сбором, хранением, распространением и защитой информации о пользователях Сервиса, регулируются настоящими Правилами, иными официальными документами Администрации Сервиса и действующим законодательством Российской Федерации.
1.4. Настоящие Правила разработаны и используются в соответствии с Пользовательским соглашением сервиса. В случае наличия противоречий между настоящими Правилами и иными официальными документами Администрации Сервиса применению подлежат
настоящие Правила.
1.6. Регистрируясь и используя Сервис и его приложения, Пользователь выражает свое согласие с условиями настоящих Правил.
1.7. В случае несогласия Пользователя с условиями настоящих Правил использование Сервиса и его приложений должно быть немедленно прекращено.

2. Условия пользования Сервисом

2.1. Оказывая услуги по использованию Сервиса и его приложений (далее – Услуги Сервиса), Администрация Сервиса, действуя разумно и добросовестно, считает, что Пользователь:
обладает всеми необходимыми правами, позволяющими ему осуществлять регистрацию и использовать настоящий Сервис;
указывает достоверную информацию о себе в объемах, необходимых для пользования Услугами Сервиса;
осознает, что информация на Сервисе, размещаемая Пользователем о себе, может становиться доступной для других Пользователей Сервиса и пользователей Интернета, может быть скопирована и распространена такими пользователями;
осознает, что некоторые виды информации, переданные им другим Пользователям, не могут быть удалены самим Пользователем;
ознакомлен с настоящими Правилами, выражает свое согласие с ними
и принимает на себя указанные в них права и обязанности.
2.2. Администрация Сервиса не проверяет достоверность получаемой (собираемой) информации о пользователях, за исключением случаев, когда такая проверка необходима в целях исполнения Администрацией Сервиса обязательств перед пользователем.
2.3. Пользователь должен воздержываться от размещения нежелательного содержимого. К нежелательному содержимому относятся: материалы откровенного эротического содержания, спам, нецензурная лексика, насилие, оскорбительное поведение и другие формы неприемлемого общения. В случае нарушения, учетная запись пользователя может быть заблокирована или удалена из Системы.

3. Цели обработки информации

3.1. Администрация Сервиса осуществляет обработку информации о Пользователях, в том числе их персональных данных, в целях выполнения обязательств Администрации Сервиса перед Пользователями в отношении использования Сервиса и его приложений.

4. Состав информации о пользователях
4.1. Персональные данные Пользователей Персональные данные Пользователей включают в себя:
4.1.1. предоставляемые Пользователями и минимально необходимые для регистрации на Сервисе: имя, пол, фотография, номер
мобильного телефона и/или адрес электронной почты;
4.1.2. дополнительно предоставляемые Пользователями по запросу Администрации Сервиса в целях исполнения Администрацией Сервиса обязательств перед Пользователями (например, в случае обращения Пользователя с просьбой о восстановлении его страницы при отсутствии привязки страницы Пользователя к мобильному телефону). Администрация Сервиса вправе, в частности, запросить у Пользователя копию документа, удостоверяющего личность, либо иного документа, содержащего имя, фамилию, фотографию Пользователя, а также иную дополнительную информацию, которая, по усмотрению Администрации Сервиса, будет являться необходимой и достаточной для идентификации такого Пользователя и позволит исключить злоупотребления и нарушения прав третьих лиц.
4.2. Иная информация о Пользователях, обрабатываемая Администрацией Сервиса
Администрация Сервиса обрабатывает также иную информацию о Пользователях, которая включает в себя:
4.2.1. стандартные данные, автоматически получаемые http-сервером при доступе к Сервису и последующих действиях Пользователя (IP- адрес хоста, вид операционной системы пользователя, страницы Сервиса, посещаемые пользователем).
4.2.2. информация, автоматически получаемая при доступе к Сервису
с использованием закладок (cookies);

5. Обработка информации о пользователях
5.1. Обработка персональных данных осуществляется на основе принципов:
а) законности целей и способов обработки персональных данных;
б) добросовестности;
в) соответствия целей обработки персональных данных целям, заранее определенным и заявленным при сборе персональных данных, а также полномочиям Администрации Сервиса;
г) соответствия объема и характера обрабатываемых персональных данных, способов обработки персональных данных целям обработки персональных данных;
д) недопустимости объединения созданных для несовместимых между собой целей баз данных, содержащих персональные данные.
5.1.1. Условия и цели обработки персональных данных Администрация Сервиса осуществляет обработку персональных
данных пользователя в целях исполнения договора между Администрацией Сервиса и Пользователем на оказание Услуг Сервиса. В силу статьи 6 Федерального закона от 27.07.2006 No 152- ФЗ «О персональных данных» отдельное согласие пользователя на обработку его персональных данных не требуется. В силу п.п. 2 п. 2 статьи 22 указанного закона Администрация Сервиса вправе осуществлять обработку персональных данных без уведомления уполномоченного органа по защите прав субъектов персональных данных.
5.1.2. Сбор персональных данных
Сбор персональных данных Пользователя осуществляется на Сервисе при регистрации, а также в дальнейшем при внесении пользователем по своей инициативе дополнительных сведений о себе с помощью инструментария Сервиса.
Персональные данные, предусмотренные п. 4.1.1. настоящих Правил, предоставляются Пользователем и являются минимально необходимыми при регистрации.
5.1.3. Хранение и использование персональных данных
Персональные данные пользователей хранятся исключительно на электронных носителях и обрабатываются с использованием автоматизированных систем, за исключением случаев, когда неавтоматизированная обработка персональных данных необходима в связи с исполнением требований законодательства.
5.1.4. Передача персональных данных
Персональные данные Пользователей не передаются каким-либо третьим лицам, за исключением случаев, прямо предусмотренных настоящими Правилами.
При указании пользователя или при наличии согласия пользователя возможна передача персональных данных пользователя третьим лицам-контрагентам Администрации Сервиса с условием принятия такими контрагентами обязательств по обеспечению конфиденциальности полученной информации, в частности, при использовании приложений.
Приложения, используемые пользователями на Сервисе, размещаются и поддерживаются третьими лицами (разработчиками), которые действуют независимо от Администрации Сервиса и не выступают от имени или по поручению Администрации Сервиса. Пользователи обязаны самостоятельно ознакомиться с правилами оказания услуг и политикой защиты персональных данных таких третьих лиц (разработчиков) до начала использования соответствующих приложений.
Предоставление персональных данных Пользователей по запросу
государственных органов (органов местного самоуправления) осуществляется в порядке, предусмотренном законодательством.
5.1.5. Уничтожение персональных данных Персональные данные пользователя уничтожаются при:
– самостоятельном удалении Пользователем данных со своей персональной страницы;
– самостоятельном удалении Пользователем своей персональной страницы
– удалении Администрацией Сервиса информации, размещаемой Пользователем, а также персональной страницы Пользователя в случаях, установленных Пользовательским соглашением.

6. Права и обязанности пользователей
6.1. Пользователи вправе:
6.1.1. осуществлять свободный бесплатный доступ к информации о себе посредством загрузки своих персональных страниц на Сервисе с использованием логина и пароля;
6.1.2. самостоятельно вносить изменения и исправления в информацию о себе на персональной странице Пользователя на Сервиса, при условии, что такие изменения и исправления содержат актуальную и достоверную информацию;
6.1.3. удалять информацию о себе со своей персональной страницы на Сервисе;
6.1.4. требовать от Администрации Сервиса уточнения своих персональных данных, их блокирования или уничтожения в случае, если такие данные являются неполными, устаревшими, недостоверными, незаконно полученными или не являются необходимыми для заявленной цели обработки и если невозможно самостоятельно выполнить действия, предусмотренные п.п. 6.1.2. и 6.1.3. настоящих Правил;
6.1.6. на основании запроса получать от Администрации Сервиса информацию, касающуюся обработки его персональных данных.
6.2.1. Администрация Сервиса не несет ответственности за разглашение персональных данных Пользователя другими Пользователями Сервиса, получившими доступ к таким данным в соответствии с выбранным Пользователем уровнем конфиденциальности.
6.2.2. При удалении персональных данных (иной пользовательской информации) с персональной страницы Пользователя или удалении
персональной страницы Пользователя с Сервиса, информация о Пользователе, скопированная другими Пользователями или хранящаяся на страницах других Пользователей, сохраняется.

7. Меры по защите информации о Пользователях

7.1. Администрация Сервиса принимает технические и организационно-правовые меры в целях обеспечения защиты персональных данных Пользователя от неправомерного или случайного доступа к ним, уничтожения, изменения, блокирования, копирования, распространения, а также от иных неправомерных действий.
7.2. Для авторизации доступа к Сервису используется логин (адрес электронной почты) и пароль Пользователя. Ответственность за сохранность данной информации несет Пользователь. Пользователь не вправе передавать собственный логин и пароль третьим лицам, а также обязан предпринимать меры по обеспечению их конфиденциальности.
7.3. В целях обеспечения более надежной защиты информации о Пользователях Администрация Сервиса использует систему привязки страницы к мобильному телефону. Для осуществления данной системы Пользователь должен предоставить Администрации Сервиса
номер своего мобильного телефона.
8. Ограничение действия Правил
Действие настоящих Правил не распространяется на действия и интернет-ресурсы третьих лиц.
Администрация Сервиса не несет ответственности за действия третьих лиц, получивших в результате использования Интернета или Услуг Сервиса доступ к информации о Пользователе в соответствии с выбранным Пользователем уровнем конфиденциальности, за последствия использования информации, которая, в силу природы Сервиса, доступна любому пользователю сети Интернет.
9. Обращения пользователей
9.1. Пользователи вправе направлять Администрации Сервиса свои запросы, в том числе запросы относительно использования их персональных данных, предусмотренные п. 6.1.6 настоящих Правил, в форме электронного документа, подписанного квалифицированной электронной подписью в соответствии с законодательством
Российской Федерации, по адресу электронной почты, указанному на сайте сервиса
9.2. Запрос, направляемый пользователем, должен содержать следующую информацию:
номер основного документа, удостоверяющего личность пользователя или его представителя;
сведения о дате выдачи указанного документа и выдавшем его органе;
сведения, подтверждающие участие пользователя в отношениях с оператором (в частности, порядковый номер id пользователя, подпись пользователя или его представителя.
9.3. Вся корреспонденция, полученная Администрацией Сервиса от пользователей (обращения в письменной или электронной форме),
относится к информации ограниченного доступа и не разглашается без письменного согласия Пользователя. Персональные данные и иная информация о Пользователе, направившем запрос, не могут быть без специального согласия Пользователя использованы иначе, как для ответа по теме полученного запроса или в случаях, прямо предусмотренных законодательством.
"""
}
