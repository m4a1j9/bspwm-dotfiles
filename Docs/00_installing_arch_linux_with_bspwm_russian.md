Данный файл содержит последовательность команд, которая нужна для полной установки системы Arch Linux.
Он также включает в себя использование билдера из репозитория, который полу-автоматически разворачивает BSPWM окружение.

Здесь хранятся самые актуальные команды. Для простоты понимания рекомендую посмотреть это [видео](https://youtu.be/9zewiGf7j-A), сравнивая с инструкцией (но предпочтение к командам отдавайте в первую очередь этому файлу).

### Подключаемся к WiFi (если используете повод, то можно пропустить)
```bash
iwctl
device list
station устройство scan
station устройство get-networks
station устройство connect SSID
ping google.com
```

### Разметка диска под UEFI GPT 
Если вы используете SSD, тогда ваши разделы будут выглядеть примерно так:
- `/dev/nvme0n1p1`
- `/dev/nvme0n1p2`

В таком случае замените `/dev/sda` на `/dev/nvme0n1`.
А разделы `/dev/sda1` и `/dev/sda2` на `/dev/nvme0n1p1` и `/dev/nvme0n1p2`.

```bash
# Выводим список дисков, что бы узнаь название нужного нам
fdisk -l

parted *название диска* # нпример, /dev/sda
mklabel gpt

# Раздел для boot-loader
mkpart ESP
# file system: ENTER
# start: 1M
# end: 1024M
set 1 boot on

# Раздел для основной системы
mkpart main
# file system: ENTER
# start: конец предыдущего раздела
# end: половина диска - 8G

# Раздел для бэкапа, указываем примерно то же размер, что и у освной сисетмы
mkpart backup
# file system: ENTER
# start: конец предыдущего раздела
# end: до конца, но нужно оставить 8G для swap

# Добавляем swap раздел
mkpart swap
# file system: ENTER
# start: конец предыдущего раздела
# end: 100% или конец предыдущего раздела + 8G

quit
```

### Подготовка разделов и монтирование
```bash
# Форматируем boot раздел под Fat32, на физ.разделе /dev/sda1 лежит boot
mkfs.fat -F 32 /dev/sda1

# Форматируем main, backup и swap под ext4
mkfs.ext4 /dev/sda2
mkfs.ext4 /dev/sda3
mkfs.ext4 /dev/sda4

# Монтируем разделы для установки системы
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
```

### Сборка ядра и базовых софтов
```bash
# Устанавливаем базовые софты
pacstrap -K /mnt base linux linux-firmware base-devel lvm2 net-tools iproute2 networkmanager vim micro efibootmgr iwd

# Генерируем fstab
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

### Настройка внутренней системы
arch-chroot /mnt

# Нужно раскомментировать ru_RU и en_US в этом файле
micro /etc/locale.gen

# Генерируем локали
locale-gen

# Настраиваем время
ln -sf /usr/share/zoneinfo/Europe/Kiev /etc/localtime
hwclock --systohc

# Указать имя хоста
echo “arch” > /etc/hostname

# Укажите пароль для root пользователя
passwd

# Добавляем нового пользователя и настраиваем права
useradd -m -G wheel,users -s /bin/bash user
passwd user

# Если планируется использовать wifi, то добавляем автозагрузку iwd
systemctl enable iwd.service

micro /etc/mkinitcpio.conf
# Пересборка ядра. Найдите строку HOOKS=(base udev autodetect modconf kms
# keyboard keymap consolefont block filesystems fsck)

# и замените на:

# HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems lvm2 fsck)

# Запустить процесс пересборки ядра
mkinitcpio -p linux
```

### Установка загрузчика (все еще в контексте /mnt)
```bash
bootctl install --path=/boot
cd /boot/loader
micro loader.conf

# Раскоментируем дефолтный конфиг и добавим:
default arch

# Создаем конфигурацию для запуска
cd /boot/loader/entries
micro arch.conf

# Вставляем в arch.conf следующее:
# UUID можно узнать командой blkid
# Для удобства можно вставить выввод команды сразу в файл
# blkid >> arch.conf
title Arch Linux by ZProger
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=UUID=айди от главной партии (на которой установлена система)

# Устанавливаем драйвера для cpu.
# Для amd
sudo pacman -S amd-ucode
# Для intel
sudo pacman -S intel-ucode

# Добавляем автозагрузку микрокода в проц (актуально, только если в качестве boot-loader использовался bootctl (он же systemd-boot))
sudo nvim /boot/loader/entries/arch.conf
# Добавляем микрокод
# initrd  /amd-ucode.img 
# или 
# initrd  /intel-ucode.img

# Выдаем права на sudo
sudo EDITOR=micro visudo
# После открытия раскомментируйте %wheel ALL=(ALL:ALL) ALL

# Выходим из системы и перезагружаемся
Ctrl+D
umount -R /mnt
reboot
```

### Устанавливаем оболочку
Если при загрузке системы вы получаете ошибки или у вас открывается окно от iso образа Arch'a, тогда необходимо отмонтировать образ или вытащить флешку.
Также убедитесь что загрузка идет под EFI, особенно это касается виртуальных машин.

Перед выполнением этих команд, авторизуйтесь в пользователя user. На этапе загрузки система попросит ввести пароль для дешифровки области жесткого диска,
и в дальнейшем вам будет предложено войти в пользователя, введя логин и пароль. После авторизации выполняем следующее:

```bash
sudo pacman -Sy
sudo pacman -S xorg bspwm sxhkd xorg-xinit xterm git python3

# Настройка xinitrc
micro /etc/X11/xinit/xinitrc

# Отключите любые другие строки exec и добавьте в конец файла строку:
exec bspwm

# Указывам заголовок для swap
mkswap /dev/sda4

# Если планируется использование github-desctop, то нужно установить keyring
sudo pacman -S gnome-keyring
```

Загрузите репозиторий локально, но перед выполнением билдера я рекомендую перейти в `Builder/packages.py` и посмотреть пакеты, которые будут установлены.
Я не советую редактировать `BASE_PACKAGES`, так как они необходимы для правильной работы оболочки, однако вы свободно можете редактировать другие виды пакетов.
На этапе билдера вам будет предложено установить `DEV_PACKAGES`, они не нужны для системы, но могут быть полезны для разработки. Выбирайте пункты на свое усмотрение.

и выполните сборку оболочки используя данные команды:
```bash
# Опциональны дирректории. Можете указать свои названия или не создавать их вовсе.
mkdir w
mkdir pw
mkdir pr
cd pw
git clone https://github.com/m4a1j9/bspwm-dotfiles.git
cd bspwm-dotfiles
python3 Builder/install.py
```

В меню необходимо предоставить разрешение на установку `dotfiles`, обновление баз, установку `BASE_PACKAGES`. Остальные пункты выбирайте самостоятельно.
Такое разделение опций позволяет выполнить только необходимое действие, к примеру лишь заменить `dotfiles` либо установить актуальные `DEV_PACKAGES` пакеты.

Если вы все сделали правильно, то после запуска вы получите готовую оболочку BSPWM. После зтого перезапускаем систему и проводим постнастройку.

### Постнастройка
Следующие пункты описывают конфигурацию дополнительного ПО. Каждый из них опционален  

#### keyring
```bash
# Если до этого установлили keyring, то дополнительно кофигурирем .xinitrc
n ~/.xinitrc
# Устонавливаем связь переменных окружения с иксами. Вставляем в начало.
# source /etc/X11/xinit/xinitrc.d/50-systemd-user.sh

# Вместе с keyring ставим GUI для более простого упраления ключами
sudo pacman -S seahorse
# Запускаем и создаем новый пароль, в название можно указать auto-unlocker. Сам пароль оставляем пустым.
# Если хочется болшей безопасности, пароль можно все-таки ввести
```

#### keyd
```bash
# Копируем конфиги и активируем демона для keyd
sudo cp ~/pw/bspwm-dotfiles/etc/keyd/* /etc/keyd/
systemctl enable keyd
```

#### nvm
```bash
# Если нужет nvm, то проделываем следующие шаги:
# Устонавливаем fisher - пакетный менеджер для fish shell
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
# Далее устанавливаем плагин, для работы bash скриптов в fish
fisher install jorgebucaran/nvm.fish
# Устанавливаем постоянную дефолтную версию
set --universal nvm_default_version 18
# Получилось использовать yarn установив его напрямую, но все еще есть баг с переключением версий и установкой пакетов глобально
suso pacman -S yarn
```

#### Браузер по умолчанию
```bash
# Устанавливаем браузер по умолчанию при помощи Default applications
# super + d -> def -> запустить и выбрать в интерфейсе, или вручную указать бинарник.
```

#### clipcat
```bash
# Проводим настройку буфер-менеджера clipcat.
# Устанавливаем дефолтные конфиги для самого менеджера
mkdir -p $XDG_CONFIG_HOME/clipcat
clipcatd default-config      > $XDG_CONFIG_HOME/clipcat/clipcatd.toml
clipcatctl default-config    > $XDG_CONFIG_HOME/clipcat/clipcatctl.toml
clipcat-menu default-config  > $XDG_CONFIG_HOME/clipcat/clipcat-menu.toml
# Так как испольщуем fish shell, менеджерунужно выдать полномочия
clipcatd completions fish
# Добавляем автозапуск
micro ~/.xinitrc
# Перед запуском оконного менеджера запускам демона
clipcatd
```

#### Настройка мониторов
```bash
# Если используется несколько мониторов, устанавливаем arandr
sudo pacman -S arandr
# Запускам и настраиваем монитроы, сохраняем конфиг и добавляем автозапуск:
micro ~/.xinitrc
# exec ~/.screenlayout/название.sh &
# Установленный порядок пригодится для конфигурации bspwm (см скрипт workspaces.sh в конфиге bspwm)
```

#### Все готово
```bash
# Перезагружаем сисему
sudo reboot

startx
```

Из-за разного железа / разных дистрибутивов и прочих моментов, могут быть небольшие проблемы в отображении иконок, в работе с батареей / яркостью. Решение этих
проблем было показано в [данном видео](https://youtu.be/9zewiGf7j-A).
