#!/bin/bash

# Aviso sobre a destruição de dados
echo "Este script irá formatar o disco /dev/nvme0n1 e instalar o sistema."
read -p "Pressione Enter para continuar ou Ctrl+C para cancelar..."

# Atualiza o sistema e instala parted para particionamento
echo "Atualizando o sistema e instalando ferramentas necessárias..."
sudo pacman -Syu parted --noconfirm

# Particionamento do disco
echo "Particionando o disco /dev/nvme0n1..."
sudo parted /dev/nvme0n1 mklabel gpt --script
sudo parted /dev/nvme0n1 mkpart primary ext4 1MiB 100% --script

# Formatação da partição
echo "Formatando a partição..."
sudo mkfs.ext4 /dev/nvme0n1p1

# Montagem da partição
echo "Montando a partição..."
sudo mount /dev/nvme0n1p1 /mnt

# Instalação do sistema base (simplificada para exemplo)
echo "Instalando o sistema base..."
sudo pacstrap /mnt base linux linux-firmware

# Gerar fstab
echo "Gerando arquivo fstab..."
sudo genfstab -U /mnt >> /mnt/etc/fstab

#!/bin/bash

# Chroot para configurar o sistema
echo "Entrando no chroot..."
sudo arch-chroot /mnt /bin/bash <<EOF

# Configuração do fuso horário
echo "Configurando o fuso horário..."
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc

# Configuração de localização
echo "Gerando locales..."
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Configuração de rede
echo "Configurando a rede..."
echo "archserver" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 archserver.localdomain archserver" >> /etc/hosts

# Configuração de senha do root
echo "Configurando senha do root..."
echo "Digite a nova senha do root:"
passwd

# Criar usuário comum com privilégios sudo
echo "Criando um novo usuário comum com privilégios sudo..."
read -p "Entre com o nome do novo usuário: " username
useradd -m -G wheel -s /bin/bash $username
echo "Digite a senha para o usuário $username:"
passwd $username
echo "$username ALL=(ALL) ALL" >> /etc/sudoers

# Instalar e configurar o bootloader
echo "Instalando o GRUB..."
pacman -S grub --noconfirm
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

EOF

# Desmonta a partição
echo "Desmontando a partição e reiniciando..."
sudo umount -R /mnt
echo "Instalação concluída. Reinicie o sistema."