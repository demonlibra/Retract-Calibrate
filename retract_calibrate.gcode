;---------------------- Калибровка длины ретракта ----------------------
;-----------------------------------------------------------------------

;============================== Параметры ==============================
;-----------------------------------------------------------------------

var temperature_hotend=245    ; Указать температуру HotEnd`а, C
var temperature_hotbed=110    ; Указать температуру стола, C

var retract_start=0.0         ; Указать начальную длину ретракта, мм
var retract_step=0.05         ; Указать шаг изменения ретракта, мм
var retract_step_height=5     ; Указать высоту печати с одной длиной ретракта, мм
var retract_number_steps=5    ; Указать количество тестовых ступеней

var tower_diameter=10         ; Указать диаметр башни, мм
var tower_perimeters=2        ; Указать количество периметров башни
var start_X=30                ; Указать координату X центра первой башни, мм
var start_Y=80                ; Указать координату Y центра первой башни, мм
var towers_distance=90        ; Указать расстояние между центрами башен, мм
var square_offset=5           ; Указать смещение квадрата вокруг тестовых линий (для прочистки сопла), мм
var brim_number=5             ; Указать количество линий каймы 

var line_width=0.4            ; Указать ширину линий, мм
var line_height=0.2           ; Указать толщину линий, мм
var filament_diameter=1.75    ; Указать диаметр прутка, мм
var extrusion_multiplier=1.05 ; Указать коэффициент экструзии

var babystepping=0.00         ; Указать BabyStepping (минус уменьшает зазор), мм
var z_lift=0.0                ; Указать высоту для холостых перемещений, мм
var z_end=50                  ; Указать смещение Z по завершению теста, мм

var print_speed_first=20      ; Указать скорость печати первого слоя, мм/сек
var print_speed_others=60     ; Указать скорость печати, мм/сек
var travel_speed=150          ; Указать скорость холостых перемещений, мм/сек
var retract_speed=30          ; Указать скорость ретракта, мм/сек

var pa=0.025                  ; Указать коэффициент Pressure Advance

var model_fan_speed=0.2       ; Указать производительность вентилятора обдува модели (от 0.0 до 1.0)
var model_fan_layer_start=3   ; Указать номер слоя, с которого включить обдув модели
;-----------------------------------------------------------------------
;-----------------------------------------------------------------------
;=======================================================================
;=======================================================================

; --------------------------- Стартовый код ----------------------------

M300 P500                                                               ; Звуковой сигнал
T0                                                                      ; Выбор инструмента 0

M572 D0 S{var.pa}                                                       ; Задание коэффициента Pressure Advance
M207 F{var.retract_speed*60} S{var.retract_start}                       ; Задание начальной скорости и длины ретракта

M83                                                                     ; Выбор относительных координат оси экструдера

M104 S{var.temperature_hotend-80}                                       ; Предварительный нагрев сопла
M190 S{var.temperature_hotbed}                                          ; Нагрев стола с ожиданием достижения температуры

G28                                                                     ; Калибровка всех осей
M290 R0 S{var.babystepping}                                             ; Задание BabyStepping 

; ------- Прочистка сопла (печать квадрата вокруг тестовых башен) ------

M300 P500                                                               ; Звуковой сигнал
G90                                                                     ; Выбор абсолютных перемещений
var brim_width=var.brim_number*var.line_width                           ; Ширина юбки
G1 X{var.start_X-var.tower_diameter/2-var.brim_width-var.square_offset} Y{var.start_Y-var.tower_diameter/2-var.brim_width-var.square_offset} Z{var.z_lift} F{var.travel_speed*60}
G1 Z0                                                                   ; Упираем сопло в стол чтобы пластик не вытекал
M109 S{var.temperature_hotend}                                          ; Нагрев HotEnd`а с ожиданием достижения температуры

; Расчёт длин перемещения и выдавливаемого филамента квадрата прочистки сопла
var move_lengthX=var.towers_distance+var.tower_diameter+var.square_offset*2+var.brim_width*2      ; Длина квадрата вдоль X
var filament_lengthX=(var.line_width*var.line_height*var.move_lengthX)/(pi*var.filament_diameter*var.filament_diameter/4)*var.extrusion_multiplier
var move_lengthY=var.tower_diameter+var.brim_width*2+var.square_offset*2                            ; Длина квадрата вдоль Y
var filament_lengthY=(var.line_width*var.line_height*var.move_lengthY)/(pi*var.filament_diameter*var.filament_diameter/4)*var.extrusion_multiplier

M300 P500                                                               ; Звуковой сигнал
G90                                                                     ; Выбор абсолютных перемещений
G1 Z{var.line_height}                                                   ; Перемещение на высоту слоя
G91                                                                     ; Выбор относительных перемещений
G1 X{var.move_lengthX} E{var.filament_lengthX} F{var.print_speed_first*60}    ; Печать линии X+
G1 Y{var.move_lengthY} E{var.filament_lengthY} F{var.print_speed_first*60}    ; Печать линии Y+
G1 X{-var.move_lengthX} E{var.filament_lengthX} F{var.print_speed_first*60}   ; Печать линии X-
G1 Y{-var.move_lengthY} E{var.filament_lengthY} F{var.print_speed_first*60}   ; Печать линии Y-
G10                                                                     ; Ретракт
G91 G1 Z{var.z_lift}                                                    ; Переместить сопло от стола

; -------------------------- Печать башен ------------------------------

var print_speed=0
var retract_length=var.retract_start                                    ; Создание переменной - длина ретракта
var print_diameter=0                                                    ; Создание переменной - диаметр печатаемой окружности
var filament_length=0                                                   ; Создание переменной - длина филамента при печати окружности
var layers_count=1                                                      ; Создание переменной - счётчик слоёв
var layers_number=floor(var.retract_number_steps*var.retract_step_height/var.line_height) ; Общее колиство слоёв
echo "Всего будет напечатано "^var.layers_number^" слоёв. Высота башен "^var.retract_number_steps*var.retract_step_height^" мм."

while var.layers_count <= var.layers_number                             ; Выполнять цикл до достижения общего количества слоёв

   if var.model_fan_layer_start==var.layers_count
      M106 S{var.model_fan_speed}                                       ; Включить обдув на указанном слое

   ;Левая башня
   if var.layers_count==1
      set var.print_diameter=var.tower_diameter+var.brim_width*2        ; Если печать 1-го слоя, то учитывать кайму
      set var.print_speed=print_speed_first                             ; Если печать 1-го слоя, задать скорость первого слоя
   else
      set var.print_diameter=var.tower_diameter                         ; Если печать НЕ 1-го слоя, то НЕ учитывать кайму
      set var.print_speed=print_speed_others                            ; Если печать НЕ 1-го слоя, задать скорость
   G90                                                                  ; Выбор абсолютных перемещений
   ; Перемещение начальную точку
   G1 X{var.start_X+var.print_diameter/2} Y{var.start_Y} Z{var.line_height*var.layers_count} F{var.travel_speed*60}
   G11                                                                  ; Возврат пластика после ретракта
   while var.print_diameter > 8*var.line_width                          ; Ограничение печати внутреннего заполнения
      ; Расчёт длины филамента
      set var.filament_length=(var.line_width*var.line_height*pi*var.print_diameter)/(pi*var.filament_diameter*var.filament_diameter/4)*var.extrusion_multiplier
      G2 I{-var.print_diameter/2} E{var.filament_length} F{var.print_speed*60}
      set var.print_diameter=var.print_diameter-var.line_width*2        ; Диаметр следующей внутренней окружности

      ; Если это НЕ 1-й слой, напечатать заданное число периметров башни
      if (var.layers_count!=1) & (var.print_diameter<(var.tower_diameter-var.tower_perimeters*var.line_width))
         break

      G91 G1 X{-var.line_width}                                         ; Переход к следующей внутренней окружности

   G10                                                                  ; Ретракт
   G91 G1 Z{var.z_lift} F{var.travel_speed*60}                          ; Опустить стол перед холостым перемещением

   if var.layers_count==1
      set var.print_diameter=var.tower_diameter+var.brim_width*2        ; Если печать 1-го слоя, то учитывать кайму
   else
      set var.print_diameter=var.tower_diameter                         ; Если печать НЕ 1-го слоя, то НЕ учитывать кайму
   G90                                                                  ; Выбор абсолютных перемещений
   G1 X{var.start_X+var.towers_distance-var.print_diameter/2} Y{var.start_Y} F{var.travel_speed*60}
   G1 Z{var.line_height*var.layers_count}                               ; Перемещение Z на высоту текущего слоя
   G11                                                                  ; Возврат пластика после ретракта
   while var.print_diameter > 8*var.line_width                          ; Ограничение печати внутреннего заполнения
      ; Расчёт длины филамента
      set var.filament_length=(var.line_width*var.line_height*pi*var.print_diameter)/(pi*var.filament_diameter*var.filament_diameter/4)*var.extrusion_multiplier
      G2 I{var.print_diameter/2} E{var.filament_length} F{var.print_speed*60} ; Печать окружности
      set var.print_diameter=var.print_diameter-var.line_width*2        ; Диаметр следующей внутренней окружности

      ; Если это НЕ 1-й слой, напечатать заданное число периметров башни
      if (var.layers_count!=1) & (var.print_diameter<(var.tower_diameter-var.tower_perimeters*var.line_width))
         break

      G91 G1 X{var.line_width}                                          ; Переход к следующей внутренней окружности

   G10                                                                  ; Ретракт
   G91 G1 Z{var.z_lift} F{var.travel_speed*60}                          ; Опустить стол перед холостым перемещением
   
   ;Расчёт длины ретракта
   if (floor(var.layers_count/floor(var.retract_step_height/var.line_height)))==(var.layers_count/floor(var.retract_step_height/var.line_height))
      echo "Напечатано "^var.layers_count*var.line_height^" мм башен. Длина ретракта "^var.retract_length^" мм."
      set var.retract_length=var.retract_length+var.retract_step        ; Расчёт длины
      M207 S{var.retract_length}                                        ; Изменение длины ретракта
      

   set var.layers_count=var.layers_count+1                              ; Номер следующего слоя

   
; -------------------------- Завершающий код ---------------------------   

M104 S0                                                                 ; Выключить нагреватель HotEnd`а
M140 S0                                                                 ; Выключить нагреватель стола
M300 P1000                                                              ; Звуковой сигнал
M107                                                                    ; Выключить вентилятор обдува модели
G10                                                                     ; Ретракт
G91 G1 Z{var.z_end} F{var.travel_speed*60}                              ; Перестить стол
M290 R0 S0                                                              ; Сбросить значение BabyStepping
M207 S0                                                                 ; Сбросить значение длины ретракта
M400                                                                    ; Дождаться завершения перемещения
M18                                                                     ; Выключить питание моторов
