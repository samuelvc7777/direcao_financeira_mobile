import 'package:flutter/material.dart';

class SensitiveDataConsentCard extends StatelessWidget {
  const SensitiveDataConsentCard({
    super.key,
    required this.accepted,
    required this.onChanged,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.privacy_tip_outlined,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uso de dados e permissões do app',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Antes de criar sua conta, leia como o Direção '
                        'Financeira pode tratar dados sensíveis para entregar '
                        'as funções do aplicativo.',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12.5,
                          height: 1.32,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ConsentSection(
              icon: Icons.person_outline_rounded,
              title: 'Conta e identificação',
              description:
                  'Nome, e-mail, senha de acesso, foto de perfil quando '
                  'informada, status da conta e dados de assinatura são usados '
                  'para autenticar você, manter sua sessão e liberar recursos '
                  'conforme seu plano.',
            ),
            _ConsentSection(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Dados financeiros',
              description:
                  'Contas, cartões, limites, últimos dígitos, transações, '
                  'categorias, faturas, pagamentos, metas, custos, ganhos e '
                  'saldos são usados para organizar seu painel financeiro, '
                  'cálculos, relatórios e alertas.',
            ),
            _ConsentSection(
              icon: Icons.route_outlined,
              title: 'Corridas, turnos e localização',
              description:
                  'Durante um turno ativo, o app pode usar localização precisa '
                  'ou aproximada, inclusive em segundo plano, para registrar '
                  'rota, distância, duração, pontos de trajeto, origem, '
                  'destino, valores e métricas operacionais. O rastreamento '
                  'começa ao iniciar o turno e para ao finalizar.',
            ),
            _ConsentSection(
              icon: Icons.image_search_outlined,
              title: 'Imagens, prints e OCR',
              description:
                  'Quando você importa um print de corrida, o app acessa a '
                  'imagem escolhida e usa reconhecimento de texto para sugerir '
                  'dados como valor, data, passageiro, origem, destino, '
                  'forma de pagamento, distância e tempo.',
            ),
            _ConsentSection(
              icon: Icons.videocam_outlined,
              title: 'Câmera, microfone e gravações',
              description:
                  'Se você ativar a gravação, o app pode usar câmera e '
                  'microfone em serviço em primeiro plano para capturar vídeo, '
                  'áudio opcional, duração, tamanho e caminho do arquivo. As '
                  'gravações ficam vinculadas ao histórico operacional do app.',
            ),
            _ConsentSection(
              icon: Icons.accessibility_new_outlined,
              title: 'Acessibilidade, bolha e sobreposição',
              description:
                  'Recursos como semáforo de corridas, bolha flutuante e '
                  'leitura de telas de apps de corrida podem usar serviço de '
                  'acessibilidade e permissão de sobreposição para detectar '
                  'ofertas, exibir alertas e apoiar sua decisão durante o uso.',
            ),
            _ConsentSection(
              icon: Icons.notifications_active_outlined,
              title: 'Notificações e execução em segundo plano',
              description:
                  'O app pode enviar notificações de ofertas, faturas, '
                  'gravações e serviços ativos, além de reiniciar recursos '
                  'necessários após atualização do app ou reinício do aparelho.',
            ),
            _ConsentSection(
              icon: Icons.cloud_sync_outlined,
              title: 'Armazenamento e sincronização',
              description:
                  'O app pode salvar dados localmente no aparelho, como sessão, '
                  'preferências, configurações e itens pendentes, e sincronizar '
                  'dados de conta, finanças, corridas, assinaturas e suporte '
                  'com os servidores configurados do aplicativo.',
            ),
            const SizedBox(height: 10),
            _ConsentNotice(
              text:
                  'As permissões sensíveis são solicitadas pelo sistema apenas '
                  'quando forem necessárias para uma função. Você pode negar ou '
                  'revogar permissões nas configurações do aparelho, mas alguns '
                  'recursos podem deixar de funcionar corretamente.',
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onChanged(!accepted),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: accepted,
                        onChanged: (value) => onChanged(value ?? false),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Li e concordo com o uso dos dados e permissões acima '
                        'para criar minha conta e usar os recursos do Direção '
                        'Financeira.',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 12.8,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentSection extends StatelessWidget {
  const _ConsentSection({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12.2,
                    height: 1.32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentNotice extends StatelessWidget {
  const _ConsentNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: colorScheme.primary,
              size: 19,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 12.1,
                  fontWeight: FontWeight.w600,
                  height: 1.32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
