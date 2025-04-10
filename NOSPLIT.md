# NOSPLIT

Флаг `NOSPLIT` в ассемблере Plan9 для Go — это важная директива, которая управляет обработкой стека в функции. Разберём его работу и последствия.

---

### **Что делает `NOSPLIT`?**
- **Отключает пролог и эпилог**:
  - **Пролог** — код, который компилятор добавляет в начало функции для:
    - Проверки и роста стека (stack check).
    - Сохранения регистров (если нужно).
    - Выделения места под локальные переменные.
  - **Эпилог** — код в конце функции для:
    - Восстановления регистров.
    - Освобождения стека.
    - Возврата управления.

- **Экономия ресурсов**:
  - Убирает лишние инструкции, сокращая размер кода.
  - Ускоряет выполнение (на несколько наносекунд).

---

### **Когда использовать `NOSPLIT`?**
1. **Функции без локальных переменных**:
   ```assembly
   TEXT ·sum(SB),NOSPLIT,$0
       ADDQ DI, SI
       MOVQ SI, AX
       RET
   ```

2. **Системные вызовы/низкоуровневый код**:
   ```assembly
   TEXT ·syscall_write(SB),NOSPLIT,$0
       MOVQ $1, AX
       SYSCALL
       RET
   ```

3. **Критичные к производительности участки**:
   Например, циклы обработки данных в ядре ОС.

---

### **Пример без `NOSPLIT`**
Если написать:
```assembly
TEXT ·example(SB), $0
    // ... код ...
    RET
```
Компилятор добавит пролог:
```assembly
example:
    SUBQ  $8, SP      // Выделит место в стеке
    // ... ваш код ...
    ADDQ  $8, SP      // Восстановит стек
    RET
```

---

### **Риски использования `NOSPLIT`**
1. **Stack Overflow**:
   - Без проверки стека функция может переполнить его, если:
     - Использует много локальных переменных.
     - Вызывает другие функции рекурсивно.

2. **Повреждение данных**:
   - Если функция пишет в стек (например, через `MOVQ AX, 0(SP)`), но не выделила для этого место.

3. **Совместимость**:
   - Код с `NOSPLIT` может перестать работать при изменении Go runtime.

---

### **Правила безопасности**
1. **Не используйте `NOSPLIT`, если**:
   - Функция вызывает другие функции (например, `CALL runtime·malloc(SB)`).
   - Вы работаете со стеком напрямую (например, `MOVQ AX, -8(SP)`).

2. **Используйте `NOSPLIT` только для**:
   - Листовых функций (не вызывающих другие функции).
   - Функций без локальных переменных.
   - Кратких операций (системные вызовы, арифметика).

---

### **Пример из вашего кода**
Исходный код:
```assembly
TEXT ·print(SB),NOSPLIT,$0
    MOVQ $1, AX       // sys_write
    MOVQ $1, DI       // stdout
    LEAQ text<>(SB), SI
    MOVQ $14, DX      // длина
    SYSCALL
    RET
```
**Почему здесь безопасно**:
- Нет локальных переменных.
- Нет вызовов других функций.
- Не используется стек для операций.

---

<!--
### **Как проверить?**
Посмотрите сгенерированный машинный код:
```bash
go tool objdump -S main.o | grep -A 10 '·print'
```
Без `NOSPLIT` вы увидите дополнительные инструкции управления стеком.

---
-->

### **Альтернативные флаги**
- `WRAPPER` — для функций-обёрток.
- `NEEDCTXT` — для функций с доступом к замыканиям.
- `NOFRAME` — запрещает создание стекового фрейма (часто используется с `NOSPLIT`).

---

### **Итог**
`NOSPLIT` — мощная оптимизация, но требует чёткого понимания:
1. **Используйте**, когда уверены, что стек не нуждается в управлении.
2. **Избегайте**, если функция сложная или вызывает другие функции.
3. **Тестируйте** код на предмет переполнения стека.